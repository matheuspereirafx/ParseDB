class RetryFailedApiCallsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "🔄 Iniciando RetryFailedApiCallsJob em #{Time.current}"

    # Processar chamadas prontas para retry
    process_ready_for_retry

    # Recuperar chamadas travadas
    recover_stuck_processing

    Rails.logger.info "✅ RetryFailedApiCallsJob finalizado"
  end

  private

  def process_ready_for_retry
    count = 0
    FailedApiCall.ready_for_retry.limit(50).each do |call|
      process_call(call) && count += 1
    end
    Rails.logger.info "📊 Processadas #{count} chamadas"
  end

  def process_call(call)
    call.with_lock do
      return false unless call.status == 'pending'

      call.mark_processing!

      # VERIFICAÇÃO CORRIGIDA: usar api_model_name, não model_name
      rate_limit = ApiRateLimit.find_by(
        service_name: call.service_name,
        api_model_name: call.api_model_name  # ← CORRIGIDO: era model_name
      )

      if rate_limit && !rate_limit.can_make_request?
        call.update!(
          status: 'pending',
          next_retry_at: rate_limit.next_allowed_at
        )
        return false
      end

      begin
        # Tenta processar baseado no serviço
        case call.service_name
        when 'gemini'
          process_gemini(call)
        else
          process_unknown(call)
        end

        call.mark_completed!
        true
      rescue RubyLLM::RateLimitError => e
        handle_rate_limit(call, e)
      rescue StandardError => e
        handle_error(call, e)
      end
    end
  end

  def process_gemini(call)
    payload = call.payload_as_hash
    chat_id = payload['chat_id']
    message = payload['message']

    chat = Chat.find_by(id: chat_id)
    unless chat
      raise "Chat #{chat_id} não encontrado"
    end

    # Usar o service para tentar novamente
    service = ChatService.new(chat)
    service.send(:call_gemini_api, message)
  end

  def process_unknown(call)
    raise "Serviço não suportado: #{call.service_name}"
  end

  def handle_rate_limit(call, error)
    # CORRIGIDO: passar api_model_name
    ApiRateLimit.update_from_error(error, call.api_model_name)  # ← CORRIGIDO: era model_name

    if call.retry_count >= call.max_retries
      call.mark_failed!
    else
      seconds = error.message.match(/retry in ([\d.]+)s/)&.[](1)&.to_f || 30
      call.retry_later(seconds)
    end
    false
  end

  def handle_error(call, error)
    if call.retry_count >= call.max_retries
      call.mark_failed!
    else
      call.retry_later(10)
    end
    false
  end

  def recover_stuck_processing
    count = FailedApiCall.stuck_processing.update_all(
      status: 'pending',
      next_retry_at: Time.current,
      updated_at: Time.current
    )
    Rails.logger.info "🔄 Recuperadas #{count} chamadas travadas" if count > 0
  end
end
