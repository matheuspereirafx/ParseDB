# app/controllers/chats_controller.rb
class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack
  before_action :set_chat, only: [:show]

  def show
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
  end

  private

  def set_stack
    @stack = current_user.stacks.find_by(id: params[:stack_id])

    if @stack.nil?
      flash[:alert] = "Stack not found. Available stacks: #{current_user.stacks.pluck(:id).join(', ')}"
      redirect_to stacks_path
    end
  end

  def set_chat
    @chat = @stack.chat || @stack.create_chat(
      title: "Chat #{@stack.name}",
      user: current_user
    )
  end
end
