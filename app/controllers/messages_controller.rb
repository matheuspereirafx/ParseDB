class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat
  before_action :set_stack  # ← ADICIONADO

  def create
    @message = @chat.messages.build(message_params)
    @message.role = "user"

    if @message.save
      ChatService.new(@chat).process_user_message(@message.content)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to stack_chat_path(@stack, @chat) }
      end
    end
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end

  def set_stack  # ← NOVO MÉTODO
    @stack = @chat.stack
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
