require 'ostruct'

# app/services/chat_service.rb
class ChatService
  SYSTEM_PROMPT = "You are an expert Database Teaching Assistant with deep specialization in: - Seed Data: Generating realistic test data, data factories, and fixture management - Schema Design: Normalization, denormalization, indexing strategies, and relationships - Database Systems: SQL/NoSQL trade-offs, query optimization, and performance tuning Your teaching style: - Explain concepts with practical, real-world examples - Provide executable code snippets in SQL, Ruby, or relevant DB languages - Break down complex topics into digestible chunks - Highlight best practices and common pitfalls - Use markdown formatting with clear section headers and syntax highlighting When responding: 1. Start with a brief, direct answer to the question 2. Include at least one concrete code example 3. Explain the 'why' behind recommendations 4. Suggest alternative approaches when relevant 5. End with a key takeaway or best practice tip Tone: Professional yet approachable, like a senior developer mentoring a junior colleague."

  def initialize(chat)
    @chat = chat
    # Modelo com cotas mais altas
    @client = RubyLLM.chat(model: 'gemini-2.5-flash-lite')
                     .with_instructions(SYSTEM_PROMPT)
    @model_name = 'gemini-2.0-flash'
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

      # Broadcast da resposta normal
      broadcast_message(assistant_msg)

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

  # ==================== BROADCAST METHODS ====================

  def broadcast_message(message)
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{@chat.id}",
      target: "messages-container",
      partial: "messages/assistant_message",
      locals: { message: message }
    )

    hide_typing_indicator
  end

  def broadcast_error_message(content)
    # Criar ID temporário
    temp_id = "temp-#{SecureRandom.hex(4)}"

    # HTML da mensagem de erro
    html = <<-HTML
      <div class="message assistant" id="#{temp_id}">
        <div class="avatar">🤖</div>
        <div>
          <div class="bubble error-message">
            #{simple_format(content)}
          </div>
          <div class="message-meta">
            Assistente · agora
            <span class="badge bg-warning text-dark ms-2">⏳ Enfileirado</span>
          </div>
        </div>
      </div>
    HTML

    # Broadcast via Turbo
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{@chat.id}",
      target: "messages-container",
      html: html
    )

    # Esconder indicador de digitação
    hide_typing_indicator

    # Remover a mensagem temporária após 10 segundos (opcional)
    Turbo::StreamsChannel.broadcast_remove_to(
      "chat_#{@chat.id}",
      target: temp_id
    )
  end

  def hide_typing_indicator
    Turbo::StreamsChannel.broadcast_update_to(
      "chat_#{@chat.id}",
      target: "typing-indicator",
      html: '<div id="typing-indicator" style="display: none;"></div>'
    )
  end

  # ==================== RATE LIMIT HANDLERS ====================

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

    error_message = "⚠️ **Rate limit atingido!**\n\n" \
                    "Sua mensagem foi enfileirada e será reenviada automaticamente em " \
                    "#{rate_limit&.time_until_allowed || 20} segundos.\n\n" \
                    "ID da fila: `#{failed_call.id}`"

    Rails.logger.warn "Rate limit error for chat #{@chat.id}: #{error.message}"

    # Broadcast da mensagem de erro
    broadcast_error_message(error_message)

    OpenStruct.new(
      content: error_message,
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

    error_message = "⏳ **Serviço ocupado**\n\n" \
                    "O limite de requisições foi atingido. Sua mensagem foi enfileirada " \
                    "e será processada automaticamente em #{wait_time} segundos.\n\n" \
                    "ID da fila: `#{failed_call.id}`"

    # Broadcast da mensagem de erro
    broadcast_error_message(error_message)

    OpenStruct.new(
      content: error_message,
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

    error_message = "🔄 **Erro temporário**\n\n" \
                    "Ocorreu um erro temporário: `#{error.message}`\n\n" \
                    "Sua mensagem foi enfileirada e será reenviada em 5 segundos.\n\n" \
                    "ID da fila: `#{failed_call.id}`"

    Rails.logger.error "Error in chat #{@chat.id}: #{error.message}"

    # Broadcast da mensagem de erro
    broadcast_error_message(error_message)

    OpenStruct.new(
      content: error_message,
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
  rescue => e
    Rails.logger.error "Failed to update rate limit usage: #{e.message}"
  end
end
