# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat

  # REMOVA as ações index, show, new - só precisa do create

  def create
    @message = @chat.messages.build(message_params)
    @message.role = "user"

    if @message.save
      # Chamar o ChatService para responder
      ChatService.new(@chat).process_user_message(@message.content)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@chat) }
      end
    else
      # Se não salvar, renderiza o chat com erro
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message-form", partial: "messages/form", locals: { chat: @chat, message: @message }) }
        format.html { redirect_to chat_path(@chat), alert: @message.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to chats_path, alert: "Chat not found"
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
