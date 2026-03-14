class CreateFailedApiCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :failed_api_calls do |t|
      t.timestamps
    end
  end
end
