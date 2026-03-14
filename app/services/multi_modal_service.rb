class MultiModalService
  def initialize(chat)
    @chat = chat
    @client = RubyLLM.chat(model: gemini-2.5-flash)
                    .with_instructions(MULTI_MODAL_PROMPT)
  end
end

 MULTI_MODAL_PROMPT = "You are a Database Teaching Assistant that can analyze images, audio, and text about database topics. Help users understand database concepts using all available media."

  @chat.messages.create!(
      content: response.content,
      role: "assistant"
    )
  end

  def process_with_audio(user_message, audio_path)
    # Salvar mensagem do usuário
    @chat.messages.create!(
      content: "#{user_message}\n\n[Audio attached]",
      role: "user"
    )

    # Enviar com áudio (Gemini 2.5 suporta áudio)
    response = @client.ask_with_audio(
      user_message,
      audio_path
    )

    # Salvar resposta
    @chat.messages.create!(
      content: response.content,
      role: "assistant"
    )
  end

  def process_with_file(user_message, file_path, file_type)
    # Salvar mensagem do usuário
    @chat.messages.create!(
      content: "#{user_message}\n\n[#{file_type} attached]",
      role: "user"
    )

    # Enviar com arquivo
    response = @client.ask_with_file(
      user_message,
      file_path,
      file_type
    )

    # Salvar resposta
    @chat.messages.create!(
      content: response.content,
      role: "assistant"
    )
  end
   
