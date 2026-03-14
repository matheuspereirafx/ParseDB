class ApiRateLimit < ApplicationRecord
  # Validações
  validates :service_name, :api_model_name, :metric_name, :limit_value, presence: true
  validates :service_name, uniqueness: { scope: [:api_model_name, :metric_name] }
  validates :limit_value, numericality: { greater_than: 0 }
  validates :current_usage, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active_limits, -> { where('next_allowed_at > ?', Time.current) }
  scope :by_service, ->(service) { where(service_name: service) }
  scope :by_model, ->(model) { where(api_model_name: model) }
  scope :exceeded, -> { where('current_usage >= limit_value') }

  # Callbacks
  before_save :set_timestamps
  after_save :log_rate_limit_change

  # Métodos de classe
  def self.update_from_error(error, model_name)
    # Pega a mensagem de erro, seja ela um objeto ou string
    error_message = error.respond_to?(:message) ? error.message : error.to_s

    if error_message =~ /limit: (\d+).*retry in ([\d.]+)s/
      limit = $1.to_i
      retry_seconds = $2.to_f

      rate_limit = find_or_create_by(
        service_name: 'gemini',
        api_model_name: model_name,
        metric_name: 'generate_content_free_tier_requests'
      ) do |rl|
        rl.limit_value = limit
        rl.current_usage = 0
      end

      rate_limit.update!(
        current_usage: limit,
        reset_after_seconds: retry_seconds,
        next_allowed_at: Time.current + retry_seconds.seconds,
        last_checked_at: Time.current
      )

      rate_limit
    end
  rescue => e
    Rails.logger.error "Erro no update_from_error: #{e.message}"
    nil
  end

  def self.check_rate_limit(service:, model:)
    find_by(service_name: service, api_model_name: model)
  end

  # Métodos de instância
  def can_make_request?
    next_allowed_at.nil? || next_allowed_at <= Time.current
  end

  def time_until_allowed
    return 0 if can_make_request?
    (next_allowed_at - Time.current).round(2)
  end

  def increment_usage!
    increment!(:current_usage)
    update!(last_checked_at: Time.current)
  end

  def reset_usage!
    update!(
      current_usage: 0,
      next_allowed_at: nil,
      reset_after_seconds: nil,
      last_checked_at: Time.current
    )
  end

  def usage_percentage
    return 0 if limit_value.zero?
    ((current_usage.to_f / limit_value) * 100).round(2)
  end

  def exceeded?
    current_usage >= limit_value
  end

  private

  def set_timestamps
    self.last_checked_at ||= Time.current
  end

  def log_rate_limit_change
    if saved_change_to_next_allowed_at? && next_allowed_at.present?
      Rails.logger.info "Rate limit for #{service_name}/#{api_model_name} set until #{next_allowed_at}"
    end
  end
end
