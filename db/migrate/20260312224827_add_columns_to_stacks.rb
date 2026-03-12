class AddColumnsToStacks < ActiveRecord::Migration[8.1]
  def change
    add_column :stacks, :name, :string
    add_column :stacks, :description, :text
    add_column :stacks, :icon, :string
  end
end
