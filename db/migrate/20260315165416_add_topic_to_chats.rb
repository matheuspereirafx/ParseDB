class AddTopicToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :topic, :string
  end
end
