class RetryChatMessagesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "💬 Iniciando RetryChatMessagesJob em #{Time.current}"

    failed_calls = FailedApiCall.where(service_name: 'gemini')
                                 .pending
                                 .ready_for_retry
                                 .limit(30)

    failed_calls.each do |call|
      retry_chat_message(call)
    end

    Rails.logger.info "💬 RetryChatMessagesJob finalizado"
  end

  private

  def retry_chat_message(call)
    call.with_lock do
      return unless call.status == 'pending'

      call.mark_processing!

      begin
        payload = call.payload_as_hash
        chat = Chat.find_by(id: payload['chat_id'])

        unless chat
          call.mark_failed!
          return
        end

        # Recriar serviço e tentar novamente
        service = ChatService.new(chat)
        result = service.process_user_message(payload['message'])

        # Se conseguiu criar a mensagem, deu certo
        if result.persisted?
          call.mark_completed!
          Rails.logger.info "✅ Mensagem do chat #{chat.id} reenviada com sucesso"
        else
          raise "Falha ao processar mensagem"
        end

      rescue RubyLLM::RateLimitError => e
        handle_rate_limit(call, e)
      rescue StandardError => e
        handle_error(call, e)
      end
    end
  end

  def handle_rate_limit(call, error)
    ApiRateLimit.update_from_error(error, call.model_name)

    if call.retry_count >= call.max_retries
      call.mark_failed!
      Rails.logger.warn "⚠️ Chat message ##{call.id} excedeu tentativas"
    else
      seconds = error.message.match(/retry in ([\d.]+)s/)&.[](1)&.to_f || 30
      call.retry_later(seconds)
      Rails.logger.info "⏳ Reagendando chat ##{call.id} para #{seconds}s"
    end
  end

  def handle_error(call, error)
    if call.retry_count >= call.max_retries
      call.mark_failed!
      Rails.logger.error "❌ Chat message ##{call.id} falhou: #{error.message}"
    else
      call.retry_later(10)
      Rails.logger.info "🔄 Reagendando chat ##{call.id} para 10s"
    end
  end
end
