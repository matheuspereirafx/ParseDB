# app/services/chat_service.rb
class ChatService
  SYSTEM_PROMPT = "You are a Database Teaching Assistant specialized in Seed Data, Schema Design, and Database Systems.\n\nAnswer concisely in Markdown with code examples."

  def initialize(chat)
    @chat = chat
    @client = RubyLLM.chat(model: 'gemini-2.5-flash-lite')
                     .with_instructions(SYSTEM_PROMPT)
  end

  def process_user_message(user_message)
    user_msg = @chat.messages.create!(
      content: user_message,
      role: "user"
    )

    add_conversation_history
    response = @client.ask(user_message)

    @chat.messages.create!(
      content: response.content,
      role: "assistant"
    )
  end

  private

  def add_conversation_history
    @chat.messages.where(role: ["user", "assistant"])
                  .order(:created_at)
                  .last(10)
                  .each do |msg|
      # ✅ AGORA PASSA UM HASH, NÃO O OBJETO
      @client.add_message(role: msg.role, content: msg.content)
    end
  end
end
