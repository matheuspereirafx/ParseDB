class FailedApiCall < ApplicationRecord
  # Associações
  belongs_to :user, optional: true

  # Validações
  validates :service_name, :api_model_name, :request_payload, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }
  validates :retry_count, numericality: { greater_than_or_equal_to: 0 }
  validates :max_retries, numericality: { greater_than: 0 }

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :processing, -> { where(status: 'processing') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :ready_for_retry, -> { pending.where('next_retry_at <= ?', Time.current) }
  scope :stuck_processing, -> { where(status: 'processing').where('updated_at < ?', 5.minutes.ago) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_model, ->(model) { where(api_model_name: model) }

  # Callbacks
  before_validation :set_defaults, on: :create
  after_create :notify_rate_limit_exceeded

  # Métodos de classe
  def self.queue_for_retry(user:, model_name:, payload:, error_message: nil, retry_in: nil)
    create!(
      user: user,
      service_name: 'gemini',
      api_model_name: model_name,
      request_payload: payload,
      error_message: error_message,
      next_retry_at: retry_in ? Time.current + retry_in.seconds : Time.current,
      status: 'pending'
    )
  end

  def self.cleanup_old_completed!(days_old: 7)
    where(status: 'completed')
      .where('created_at < ?', days_old.days.ago)
      .delete_all
  end

  def self.stats
    {
      pending: pending.count,
      processing: processing.count,
      completed: completed.count,
      failed: failed.count,
      ready_for_retry: ready_for_retry.count
    }
  end

  # Métodos de instância
  def mark_processing!
    update!(status: 'processing', updated_at: Time.current)
  end

  def mark_completed!
    update!(status: 'completed', updated_at: Time.current)
  end

  def mark_failed!
    update!(status: 'failed', updated_at: Time.current)
  end

  def retry_later(delay_seconds)
    increment!(:retry_count)
    update!(
      status: 'pending',
      next_retry_at: Time.current + delay_seconds.seconds,
      updated_at: Time.current
    )
  end

  def can_retry?
    retry_count < max_retries
  end

  def exceeded_max_retries?
    retry_count >= max_retries
  end

  def time_until_retry
    return 0 if next_retry_at.nil? || next_retry_at <= Time.current
    (next_retry_at - Time.current).round(2)
  end

  def retryable?
    pending? && next_retry_at <= Time.current
  end

  def payload_as_hash
    request_payload.is_a?(String) ? JSON.parse(request_payload) : request_payload
  rescue
    {}
  end

  private

  def set_defaults
    self.status ||= 'pending'
    self.retry_count ||= 0
    self.max_retries ||= 3
    self.next_retry_at ||= Time.current
  end

  def notify_rate_limit_exceeded
    if error_message.present? && error_message.include?('RateLimit')
      Rails.logger.warn "Rate limit exceeded for user #{user_id} on #{api_model_name}"
    end
  end
end
