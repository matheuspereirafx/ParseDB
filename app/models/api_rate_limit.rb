class ApiRateLimit < ApplicationRecord
  # Atributos esperados:
  # service_name (string)
  # model_name (string)
  # metric_name (string)
  # limit_value (integer)
  # current_usage (integer)
  # reset_at (datetime)

  validates :service_name, :model_name, :metric_name, presence: true
  validates :limit_value, :current_usage, numericality: { greater_than_or_equal_to: 0 }

  def self.check_rate_limit(service:, model:)
    find_by(service_name: service, model_name: model)
  end

  def self.update_from_error(error, model_name)
    # Extrair informações do erro e atualizar/registrar
    rate_limit = find_or_initialize_by(
      service_name: 'gemini',
      model_name: model_name,
      metric_name: 'generate_content_free_tier_requests'
    )

    rate_limit.limit_value = 20
    rate_limit.current_usage = (rate_limit.current_usage || 0) + 1
    rate_limit.reset_at = Time.current + 60 if error.message =~ /retry in (\d+\.?\d*)s/
    rate_limit.save
    rate_limit
  end

  def can_make_request?
    current_usage < limit_value
  end

  def time_until_allowed
    return 0 if can_make_request?
    return 0 unless reset_at
    [0, (reset_at - Time.current).ceil].max
  end

  def increment_usage!
    update!(current_usage: current_usage + 1)
  end
end
