class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stack
  before_action :set_chat

  def create
    puts "\n" + "=" * 60
    puts "🔍 DEBUG - MessagesController#create"
    puts "=" * 60
    puts "params.inspect: #{params.inspect}"
    puts "params[:message]: #{params[:message].inspect}"
    puts "=" * 60

    begin
      @message = @chat.messages.build(message_params)
      @message.role = "user"

      puts "Mensagem antes de salvar: #{@message.inspect}"
      puts "Mensagem válida? #{@message.valid?}"
      puts "Erros: #{@message.errors.full_messages}" if @message.errors.any?

      if @message.save
        puts "✅ Mensagem salva com ID: #{@message.id}"
        result = ChatService.new(@chat).process_user_message(@message.content)

        if result.is_a?(OpenStruct) && result.content.include?("enfileirada")
          flash[:warning] = result.content
        end

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to stack_chat_path(@stack, @chat) }
        end
      else
        puts "❌ ERRO AO SALVAR: #{@message.errors.full_messages}"
        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace("message-form",
              partial: "messages/form",
              locals: { chat: @chat, message: @message }
            )
          }
          format.html {
            redirect_to stack_chat_path(@stack, @chat),
            alert: @message.errors.full_messages.join(", ")
          }
        end
      end
    rescue => e
      puts "💥 EXCEÇÃO: #{e.class} - #{e.message}"
      puts e.backtrace.first(5)
      raise
    end
  end

  private

  def set_stack
    @stack = Stack.find(params[:stack_id])
  end

  def set_chat
    @chat = @stack.chats.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
