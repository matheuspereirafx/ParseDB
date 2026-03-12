class AllowNullForStacksIdInChats < ActiveRecord::Migration[8.1]
  def change
    change_column_null :chats, :stacks_id, true
  end
end
