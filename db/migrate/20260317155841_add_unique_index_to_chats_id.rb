class AddUniqueIndexToChatsId < ActiveRecord::Migration[8.1]
  def change
     add_index :chats, :id, unique: true, name: "index_chats_on_id_unique"
  end
end
