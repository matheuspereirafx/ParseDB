# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associações existentes
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats

  # NOVA associação com Stacks
  has_many :stacks, dependent: :destroy  # ← Adicione esta linha!
end
