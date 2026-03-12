class Message < ApplicationRecord
  belongs_to :chat

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: [ "user", "assistant" ] }

  scope :user, -> { where(role: "user") }
  scope :assistant, -> { where(role: "assistant") }
end
