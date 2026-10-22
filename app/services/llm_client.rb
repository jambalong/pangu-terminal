require "timeout"

class LlmClient
  TIMEOUT_SECONDS = 20
  FALLBACK_MESSAGE = "Advisor is temporarily unavailable. Check your farming priority ranking above for recommendations."

  def self.ask(prompt)
    Timeout.timeout(TIMEOUT_SECONDS) do
      chat = RubyLLM.chat
      chat.ask(prompt).content
    end
  rescue Timeout::Error, RubyLLM::RateLimitError, RubyLLM::ContextLengthExceededError
    FALLBACK_MESSAGE
  rescue => e
    Rails.logger.error("LlmClient error: #{e.class} #{e.message}")
    FALLBACK_MESSAGE
  end

  def self.fallback?(response)
    response == FALLBACK_MESSAGE
  end
end
