# app/models/stack.rb
class Stack < ApplicationRecord
  belongs_to :user
  has_one :chat, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true

  # Remover o after_create que depende do RubyLLM
  # after_create :create_default_chat

  # Criar um método manual para criar o chat
  def create_chat_manually
    return chat if chat.present?

    Chat.create!(
      stack: self,
      user: user,
      title: "Chat #{name}"
    )
  end
end
