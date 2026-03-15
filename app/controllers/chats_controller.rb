# app/controllers/chats_controller.rb
class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack
  before_action :set_chat, only: [:show]

  # GET /stacks/:stack_id/chat
  def show
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
    render :show
  end

  # POST /stacks/:stack_id/chat/messages
  # (as mensagens são criadas pelo MessagesController)

  private

  def set_stack
    @stack = current_user.stacks.find(params[:stack_id])
  end

  def set_chat
    @chat = @stack.chat || @stack.create_chat(
      title: "Chat #{@stack.name}",
      user: current_user
    )
  end
end
