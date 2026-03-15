# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_15_134601) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_rate_limits", force: :cascade do |t|
    t.string "api_model_name", limit: 50, null: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.integer "current_usage", default: 0
    t.timestamptz "last_checked_at", default: -> { "CURRENT_TIMESTAMP" }
    t.integer "limit_value", null: false
    t.string "metric_name", limit: 100, null: false
    t.timestamptz "next_allowed_at"
    t.decimal "reset_after_seconds", precision: 10, scale: 3
    t.string "service_name", limit: 50, null: false
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["next_allowed_at"], name: "idx_api_rate_limits_next_allowed"
    t.unique_constraint ["service_name", "api_model_name", "metric_name"], name: "unique_service_model_metric"
  end

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "stack_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["stack_id"], name: "index_chats_on_stack_id"
    t.index ["stack_id"], name: "index_chats_on_stack_id_unique", unique: true
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "failed_api_calls", force: :cascade do |t|
    t.string "api_model_name", limit: 50, null: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.text "error_message"
    t.integer "max_retries", default: 3
    t.timestamptz "next_retry_at"
    t.jsonb "request_payload"
    t.integer "retry_count", default: 0
    t.string "service_name", limit: 50, null: false
    t.string "status", limit: 20, default: "pending"
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.bigint "user_id"
    t.index ["next_retry_at"], name: "idx_failed_calls_next_retry", where: "((status)::text = 'pending'::text)"
    t.index ["status"], name: "idx_failed_calls_status"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.string "role"
    t.text "thinking_signature"
    t.text "thinking_text"
    t.integer "thinking_tokens"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "stacks", force: :cascade do |t|
    t.string "content"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.string "name"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_stacks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "chats", "stacks"
  add_foreign_key "chats", "users"
  add_foreign_key "failed_api_calls", "users", name: "failed_api_calls_user_id_fkey"
  add_foreign_key "messages", "chats"
  add_foreign_key "stacks", "users"
end
