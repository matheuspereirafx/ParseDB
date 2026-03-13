class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack
  before_action :set_chat, only: [:show]

  def index
    @chats = @stack.chats.where(user: current_user).order(created_at: :desc)
  end

  def show
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = @stack.chats.new(chat_params)
    @chat.user = current_user

    if @chat.save
      redirect_to stack_chat_path(@stack, @chat), notice: "Chat criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_stack
    @stack = Stack.find(params[:stack_id])
  end

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end

  def chat_params
    params.require(:chat).permit(:title)
  end
end
