class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show]

  def index
    @chats = current_user.chats.order(created_at: :desc)
    puts "🔍 @chats = #{@chats.inspect}" # Para debug no terminal
  end

  def show
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = Chat.new(chat_params)
    @chat.user = current_user

    if Stack.exists?
      @chat.stacks_id = Stack.first.id
    else
      flash[:alert] = "Crie um stack primeiro antes de criar um chat"
      redirect_to new_chat_path and return
    end

    if @chat.save
      redirect_to @chat, notice: "Chat criado com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def chat_params
    params.require(:chat).permit(:title)
  end
end
