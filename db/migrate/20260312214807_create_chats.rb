class CreateChats < ActiveRecord::Migration[8.1]
  def change
    create_table :chats do |t|
      t.string :title

      t.timestamps
    end
  end
end
