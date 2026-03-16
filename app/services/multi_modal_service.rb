class MultiModalService
  MULTI_MODAL_PROMPT = "You are a Database Senior Teacher from Le Wagon, specialized in analyzing visual and file-based database content.\n\n" \
  "WHAT YOU ANALYZE:\n" \
  "• Terminal screenshots – identify error messages, stack traces, migration failures\n" \
  "• Schema diagrams – review table relationships, missing foreign keys, naming conventions\n" \
  "• Code screenshots – spot bugs in SQL, ActiveRecord queries, seed files, migrations\n" \
  "• CSV/SQL files – analyze structure, suggest improvements, identify data quality issues\n\n" \
  "YOUR ANALYSIS FORMAT:\n" \
  "1. **What I see** – describe what's in the image/file (1-2 sentences)\n" \
  "2. **The problem** – identify the issue clearly\n" \
  "3. **Fix** – working code in ```sql, ```ruby, or ```yaml\n" \
  "4. **Pro Tip** – one thing to avoid next time\n\n" \
  "RULES:\n" \
  "• Always assume the user is a Le Wagon beginner\n" \
  "• Be direct – point to the exact line or column causing the issue\n" \
  "• If the image is unclear, ask for a better screenshot\n" \
  "• Never answer questions outside database topics"

  def initialize(chat)
    @chat = chat
    @client = RubyLLM.chat(model: 'gemini-2.5-flash')
                     .with_instructions(MULTI_MODAL_PROMPT)
  end

  def process_with_image(user_message, image_path)
    @chat.messages.create!(
      content: "#{user_message}\n\n[Image attached]",
      role: "user"
    )

    response = @client.ask(user_message, with: { image: image_path })

    @chat.messages.create!(
      content: response.content,
      role: "assistant"
    )
  end

  def process_with_file(user_message, file_path, file_type)
    @chat.messages.create!(
      content: "#{user_message}\n\n[#{file_type} attached]",
      role: "user"
    )

    response = @client.ask(user_message, with: { file: file_path })

    @chat.messages.create!(
      content: response.content,
      role: "assistant"
    )
  end
end
