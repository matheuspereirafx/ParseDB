class AddFieldsToStacks < ActiveRecord::Migration[8.1]
  def change
    add_column :stacks, :title, :string
    add_column :stacks, :content, :string
  end
end
