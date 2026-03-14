class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack
  before_action :set_chat, only: [:show, :update, :destroy]

  def index
    @chats = @stack.chats.where(user: current_user).order(created_at: :desc)
  end

  def show
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
  end

  def create
    @chat = @stack.chats.new(user: current_user)
    @chat.title = "Chat #{Time.current.strftime('%d/%m %H:%M')}"

    # 🟢 REMOVA este bloco inteiro - é desnecessário e causa erro
    # if Stack.exists?
    #   @chat.stacks_id = Stack.first.id
    # else
    #   flash[:alert] = "Crie um stack primeiro antes de criar um chat"
    #   redirect_to new_chat_path and return
    # end

    if @chat.save
      redirect_to stack_chat_path(@stack, @chat)
    else
      redirect_to stack_chats_path(@stack), alert: "Erro ao criar chat."
    end
  end

  def update
    if @chat.update(chat_params)
      redirect_to stack_chat_path(@stack, @chat)
    else
      redirect_to stack_chat_path(@stack, @chat), alert: "Erro ao atualizar."
    end
  end

  def destroy
    @chat.destroy
    redirect_to stack_chats_path(@stack), notice: "Chat excluído."
  end

  private

  def set_stack
    @stack = Stack.find(params[:stack_id])
  end

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def chat_params
    params.require(:chat).permit(:title)
  end
end
