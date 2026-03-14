class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack
  before_action :set_chat

  def create
    @message = @chat.messages.build(message_params)
    @message.role = "user"

    if @message.save
      ChatService.new(@chat).process_user_message(@message.content)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to stack_chat_path(@stack, @chat) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message-form", partial: "messages/form", locals: { chat: @chat, message: @message }) }
        format.html { redirect_to stack_chat_path(@stack, @chat), alert: @message.errors.full_messages.join(", ") }
      end
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
