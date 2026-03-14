class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :update, :destroy]
  before_action :set_stack_from_chat, only: [:show]

  def index
    @stack = Stack.find(params[:stack_id])
    @chats = @stack.chats.where(user: current_user).order(created_at: :desc)
  end

  def show
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
    # @stack já vem do before_action :set_stack_from_chat
  end

  def create
    @stack = Stack.find(params[:stack_id])
    @chat = @stack.chats.new(user: current_user)
    @chat.title = "Chat #{Time.current.strftime('%d/%m %H:%M')}"

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
    @stack = @chat.stack
    @chat.destroy
    redirect_to stack_chats_path(@stack), notice: "Chat excluído."
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def set_stack_from_chat
    @stack = @chat.stack
    unless @stack
      # Redireciona para root com mensagem de erro
      redirect_to root_path, alert: "Stack não encontrado para este chat." and return
    end
  end

  def chat_params
    params.require(:chat).permit(:title)
  end
end
