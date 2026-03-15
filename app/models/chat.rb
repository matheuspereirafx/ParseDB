# app/models/chat.rb
class Chat < ApplicationRecord
  acts_as_chat messages: :messages, model: :model  # ← NOVO

  belongs_to :user
  belongs_to :stack
  has_many :messages, dependent: :destroy
  # remove :messages se já tinha
end

# app/models/message.rb
class Message < ApplicationRecord
  acts_as_message chat: :chat, tool_calls: :tool_calls, model: :model  # ← NOVO

  belongs_to :chat
  belongs_to :user
  # Remove validação de presence do content se existir
  validates :role, presence: true
  # NÃO validar :content
end
