class AddUniqueIndexToChats < ActiveRecord::Migration[8.1]
  def change
    add_index :chats, :stack_id, unique: true, name: "index_chats_on_stack_id_unique"
  end
end
