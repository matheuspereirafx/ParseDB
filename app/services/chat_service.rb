require 'ostruct' 
class ChatService
  SYSTEM_PROMPT = "You are a Database Teaching Assistant specialized in Seed Data, Schema Design, and Database Systems.\n\nAnswer concisely in Markdown with code examples."

  def initialize(chat)
    @chat = chat
    @client = RubyLLM.chat(model: 'gemini-2.5-flash-lite')
                     .with_instructions(SYSTEM_PROMPT)
    @model_name = 'gemini-2.5-flash-lite'
  end

  def process_user_message(user_message)
    # PASSO 1: Verificar rate limit ANTES de tentar
    rate_limit = ApiRateLimit.check_rate_limit(
      service: 'gemini',
      model: @model_name
    )

    if rate_limit && !rate_limit.can_make_request?
      return handle_rate_limited(user_message, rate_limit.time_until_allowed)
    end

    # PASSO 2: Tentar processar a mensagem
    begin
      user_msg = @chat.messages.create!(
        content: user_message,
        role: "user"
      )

      add_conversation_history
      response = @client.ask(user_message)

      assistant_msg = @chat.messages.create!(
        content: response.content,
        role: "assistant"
      )

      # PASSO 3: Atualizar uso com sucesso
      update_successful_usage(rate_limit)

      # Retornar resposta normal
      assistant_msg

    rescue RubyLLM::RateLimitError => e
      # PASSO 4: Lidar com rate limit error
      handle_rate_limit_error(user_message, e)
    rescue StandardError => e
      # PASSO 5: Lidar com outros erros
      handle_general_error(user_message, e)
    end
  end

  private

  def add_conversation_history
    @chat.messages.where(role: ["user", "assistant"])
                  .order(:created_at)
                  .last(10)
                  .each do |msg|
      @client.add_message(role: msg.role, content: msg.content)
    end
  end

  # NOVOS MÉTODOS PARA RATE LIMIT

  def handle_rate_limit_error(user_message, error)
    # Atualizar tracking do rate limit
    rate_limit = ApiRateLimit.update_from_error(error, @model_name)

    # Criar registro de falha para retry
    failed_call = FailedApiCall.queue_for_retry(
      user: @chat.user,
      model_name: @model_name,
      payload: {
        chat_id: @chat.id,
        message: user_message,
        conversation_history: @chat.messages.last(10).map(&:content),
        error: error.message
      },
      error_message: error.message,
      retry_in: rate_limit&.time_until_allowed || 20
    )

    Rails.logger.warn "Rate limit error for chat #{@chat.id}: #{error.message}"

    # Retornar objeto que imita uma mensagem de erro
    OpenStruct.new(
      content: "⚠️ **Rate limit atingido!**\n\nSua mensagem foi enfileirada e será reenviada automaticamente em #{rate_limit&.time_until_allowed || 20} segundos.\n\nID da fila: `#{failed_call.id}`",
      role: "assistant",
      id: nil,
      persisted?: false
    )
  end

  def handle_rate_limited(user_message, wait_time)
    # Enfileirar sem nem tentar chamar a API
    failed_call = FailedApiCall.queue_for_retry(
      user: @chat.user,
      model_name: @model_name,
      payload: {
        chat_id: @chat.id,
        message: user_message,
        conversation_history: @chat.messages.last(10).map(&:content),
        prechecked: true
      },
      error_message: "Pre-check: rate limit active",
      retry_in: wait_time
    )

    OpenStruct.new(
      content: "⏳ **Serviço ocupado**\n\nO limite de requisições foi atingido. Sua mensagem foi enfileirada e será processada automaticamente em #{wait_time} segundos.\n\nID da fila: `#{failed_call.id}`",
      role: "assistant",
      id: nil,
      persisted?: false
    )
  end

  def handle_general_error(user_message, error)
    # Para erros não relacionados a rate limit
    failed_call = FailedApiCall.queue_for_retry(
      user: @chat.user,
      model_name: @model_name,
      payload: {
        chat_id: @chat.id,
        message: user_message,
        conversation_history: @chat.messages.last(10).map(&:content)
      },
      error_message: error.message,
      retry_in: 5
    )

    Rails.logger.error "Error in chat #{@chat.id}: #{error.message}"

    OpenStruct.new(
      content: "🔄 **Erro temporário**\n\nOcorreu um erro temporário: `#{error.message}`\n\nSua mensagem foi enfileirada e será reenviada em 5 segundos.\n\nID da fila: `#{failed_call.id}`",
      role: "assistant",
      id: nil,
      persisted?: false
    )
  end

  def update_successful_usage(rate_limit)
    if rate_limit
      rate_limit.increment_usage!
    else
      # Criar registro se não existir
      ApiRateLimit.create!(
        service_name: 'gemini',
        model_name: @model_name,
        metric_name: 'generate_content_free_tier_requests',
        limit_value: 20,
        current_usage: 1
      )
    end
  end
end
