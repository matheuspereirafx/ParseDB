# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  config.gemini_api_key = ENV["GEMINI_API_KEY"]
end

puts "✅ RubyLLM configurado" if Rails.env.development?
