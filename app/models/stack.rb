class Stack < ApplicationRecord
  has_many :chats, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true
end
