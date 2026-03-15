# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack
  before_action :set_chat

  def create
    @message = @chat.messages.build(
      content: message_params[:content],
      role: "user",
      user: current_user
    )

    if @message.save
      # GUARDAR O RETORNO do service em uma variável
      @assistant_message = ChatService.new(@chat).process_user_message(
        @message.content,
        current_user
      )

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to stack_chat_path(@stack) }
      end
    end
  end

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

  def message_params
    params.require(:message).permit(:content)
  end
end
