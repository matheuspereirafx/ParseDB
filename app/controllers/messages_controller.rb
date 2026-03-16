class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack
  before_action :set_chat

  def create
    @message = @chat.messages.new(message_params)
    @message.role = "user"

    if @message.save
      if @message.file.attached?
        process_file(@message.file)
      else
        send_question
      end

      Message.create!(role: "assistant", content: @response.content, chat: @chat)
      redirect_to stack_chat_path(@stack, @chat)
    else
      @messages = @chat.messages.order(:created_at)
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def send_question(model: "gemini-2.5-flash", with: {})
    provider = model.start_with?("gemini") ? "gemini" : "openai"
    ruby_llm_chat = RubyLLM.chat.with_model(model, provider: provider, assume_exists: true)
    ruby_llm_chat.with_instructions(@stack.content.to_s)

    @chat.messages.order(:created_at).each do |msg|
      ruby_llm_chat.add_message(role: msg.role, content: msg.content)
    end

    @response = ruby_llm_chat.ask(@message.content, with: with)
  end

  def process_file(file)
    if file.content_type == "application/pdf"
      send_question(model: "gemini-2.5-flash", with: { pdf: @message.file.url })
    elsif file.image?
      send_question(model: "gpt-4o", with: { image: @message.file.url })
    elsif file.audio?
      temp_file = Tempfile.new([ "audio", File.extname(@message.file.filename.to_s) ])

      URI.open(@message.file.url) do |remote_file|
        IO.copy_stream(remote_file, temp_file)
      end

      send_question(model: "gpt-4o-audio-preview", with: { audio: temp_file.path })
      temp_file.unlink
    end
  end

  def set_stack
    @stack = Stack.find(params[:stack_id])
  end

  def set_chat
    @chat = @stack.chats.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content, :file)
  end
end
