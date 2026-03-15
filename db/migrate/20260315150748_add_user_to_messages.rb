# db/migrate/20260315150748_add_user_to_messages.rb
class AddUserToMessages < ActiveRecord::Migration[8.1]
  def change
    # 1. Adicionar coluna permitindo null temporariamente
    add_reference :messages, :user, foreign_key: true

    # 2. Preencher user_id para mensagens existentes (usando o user do chat)
    reversible do |dir|
      dir.up do
        # Associar mensagens existentes ao usuário do chat
        execute <<-SQL
          UPDATE messages
          SET user_id = (
            SELECT user_id FROM chats WHERE chats.id = messages.chat_id
          )
          WHERE user_id IS NULL
        SQL
      end
    end

    # 3. Agora podemos adicionar a constraint not null
    change_column_null :messages, :user_id, false
  end
end
