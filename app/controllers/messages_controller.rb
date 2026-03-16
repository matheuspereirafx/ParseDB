class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack
  before_action :set_chat

  def create
    @message = @chat.messages.new(message_params)
    @message.role = "user"

    if @message.save
      system_prompt = @stack.content.to_s
      ruby_llm_chat = RubyLLM.chat(model: "gemini-2.5-flash")
      response = ruby_llm_chat.with_instructions(system_prompt).ask(@message.content)
      Message.create!(role: "assistant", content: response.content, chat: @chat)
      redirect_to stack_chat_path(@stack, @chat)
    else
      @messages = @chat.messages.order(:created_at)
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def set_stack
    @stack = Stack.find(params[:stack_id])
  end

  def set_chat
    @chat = @stack.chats.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
