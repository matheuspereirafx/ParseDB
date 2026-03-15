# app/models/stack.rb
class Stack < ApplicationRecord
  belongs_to :user
  has_one :chat, dependent: :destroy  # ← UM chat por stack!

  validates :name, presence: true
  validates :description, presence: true

  # Opcional: criar chat automaticamente quando o stack for criado
  after_create :create_default_chat

  private

  def create_default_chat
    create_chat!(
      title: "Chat #{name}",
      user: User.first # ou associar ao dono do stack
    )
  rescue => e
    Rails.logger.error "Erro ao criar chat para stack #{id}: #{e.message}"
  end
end
