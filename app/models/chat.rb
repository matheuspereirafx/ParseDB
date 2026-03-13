class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :stack, foreign_key: "stacks_id", optional: true
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  before_validation :set_default_title, on: :create

  private

  def set_default_title
    self.title ||= "Chat #{Time.current.strftime('%d/%m %H:%M')}"
  end
end
