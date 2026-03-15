# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  config.gemini_api_key = ENV["GEMINI_API_KEY"]

  # Enable the new Rails-like API
  config.use_new_acts_as = true

end

puts "✅ RubyLLM configurado" if Rails.env.development?
