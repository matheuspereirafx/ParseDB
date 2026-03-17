class Message < ApplicationRecord
  belongs_to :chat
  has_one_attached :file

  MAX_FILE_SIZE_MB = 10

  validates :content, presence: true, unless: -> { role == "assistant" }
  validates :role, presence: true, inclusion: { in: ["user", "assistant"] }

  validates :content, length: { minimum: 10, maximum: 1000 }, if: -> { role == "user" }

  validate :file_size_limit

  scope :user, -> { where(role: "user") }
  scope :assistant, -> { where(role: "assistant") }

  after_create_commit :broadcast_append_to_chat

  private

  def broadcast_append_to_chat
    broadcast_append_to chat, target: "messages", partial: "messages/message", locals: { message: self }
  end

  def file_size_limit
    if file.attached? && file.byte_size > MAX_FILE_SIZE_MB.megabytes
      errors.add(:file, "size must be less than #{MAX_FILE_SIZE_MB}MB")
    end
  end
end
