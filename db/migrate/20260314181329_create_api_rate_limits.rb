class CreateApiRateLimits < ActiveRecord::Migration[8.1]
  def change
    create_table :api_rate_limits do |t|
      t.timestamps
    end
  end
end
