class ChangeChatsToSinglePerStack < ActiveRecord::Migration[8.1]
  def up
    Stack.find_each do |stack|
      if stack.chats.count > 1
        latest_chat = stack.chats.order(updated_at: :desc).first

        stack.chat.where.not(id: latest_chat.id).destroy_all

        puts "Stack ##{stack.id}: manteve chat ##{latest_chat.id}, removeu #{stack.chats.count - 1} chats"

      end
    end

    add_index :chats, :stack_id, unique: true, name: "index_chats_on_stack_id_unique"
  end

  def down
    remove_index :chats, name: "index_chats_on_stack_id_unique"
  end
end
