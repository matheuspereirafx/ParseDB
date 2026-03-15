# app/models/chat.rb
class Chat < ApplicationRecord
  belongs_to :stack
  belongs_to :user
  has_many :messages, dependent: :destroy

  validates :title, presence: true
  validates :topic, presence: true  # Tópico é obrigatório

  TOPICS = [
    'Seed Data',
    'Schema Design',
    'Database Setup',
    'Indexes',
    'Migrations',
    'Associations',
    'Performance',
    'Backup/Restore'
  ].freeze

  validates :topic, inclusion: { in: TOPICS, allow_blank: false }
end
