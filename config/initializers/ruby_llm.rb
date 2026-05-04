require "ruby_llm"

RubyLLM.configure do |config|
  config.gemini_api_key = Rails.application.credentials.gemini_api_key!
  config.default_model = "gemini-3.1-flash-lite-preview"
  config.logger = Rails.logger
  config.log_level = Rails.env.production? ? :info : :debug
  config.request_timeout = 30
end
