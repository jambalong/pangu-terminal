class LlmClient
  def self.ask(prompt)
    chat = RubyLLM.chat
    chat.ask(prompt).content
  rescue RubyLLM::RateLimitError, RubyLLM::ContextLengthExceededError
    "Advisor is temporarily unavailable. Check your farming priority ranking above for recommendations."
  rescue => e
    Rails.logger.error("LlmClient error: #{e.class} #{e.message}")
    "Advisor is temporarily unavailable. Check your farming priority ranking above for recommendations."
  end
end
