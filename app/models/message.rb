# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :chat

  MAX_USER_MESSAGES = 100

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: [ "user", "assistant" ] }

  scope :user, -> { where(role: "user") }
  scope :assistant, -> { where(role: "assistant") }

  # Validação para limitar mensagens do usuário
  validate :user_message_limit, if: -> { role == "user" }

  private

  def user_message_limit
    # CORREÇÃO: Usar self.chat (não Message)
    if self.chat.messages.where(role: "user").count >= MAX_USER_MESSAGES
      errors.add(:content, "You can only send #{MAX_USER_MESSAGES} messages per chat")
    end
  end
end
