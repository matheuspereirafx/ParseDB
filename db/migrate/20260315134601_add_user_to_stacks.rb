class AddUserToStacks < ActiveRecord::Migration[8.1]
  def change
    add_reference :stacks, :user, foreign_key: true
  end
end
