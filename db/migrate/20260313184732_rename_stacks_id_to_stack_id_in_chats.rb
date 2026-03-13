class RenameStacksIdToStackIdInChats < ActiveRecord::Migration[8.1]
  def change
    rename_column :chats, :stacks_id, :stack_id
  end
end
