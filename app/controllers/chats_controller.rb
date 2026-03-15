class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack, if: -> { params[:stack_id].present? }
  before_action :set_chat, only: [:show, :update, :destroy]

  # GET /stacks/:stack_id/chats
  # GET /chats
  def index
    if @stack
      # Chats de um stack específico
      @chats = @stack.chats.where(user: current_user).order(created_at: :desc)
    else
      # Todos os chats do usuário (globais)
      @chats = current_user.chats.order(created_at: :desc)
    end
  end

  # GET /stacks/:stack_id/chats/:id
  # GET /chats/:id
  def show
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
  end

  # POST /stacks/:stack_id/chats
  # POST /chats
  def create
    if @stack
      # Chat dentro de um stack
      @chat = @stack.chats.new(user: current_user)
    else
      # Chat global (sem stack)
      @chat = current_user.chats.new
    end

    @chat.title = "Chat #{Time.current.strftime('%d/%m %H:%M')}"

    if @chat.save
      redirect_to chat_path(@chat), notice: "Chat criado com sucesso!"
    else
      redirect_to chats_path, alert: "Erro ao criar chat: #{@chat.errors.full_messages.join(', ')}"
    end
  end

  # GET /chats/new
  def new
    @chat = Chat.new
  end

  # PATCH/PUT /chats/:id
  def update
    if @chat.update(chat_params)
      redirect_to chat_path(@chat), notice: "Chat atualizado!"
    else
      redirect_to chat_path(@chat), alert: "Erro ao atualizar."
    end
  end

  # DELETE /chats/:id
  def destroy
    @chat.destroy
    redirect_to chats_path, notice: "Chat excluído."
  end

  private

  def set_stack
    @stack = Stack.find(params[:stack_id])
  end

  def set_chat
    @chat = current_user.chats.find(params[:id])
    # Se o chat pertence a um stack, carrega o stack também
    @stack = @chat.stack if @chat.stack.present?
  end

  def chat_params
    params.require(:chat).permit(:title)
  end
end
