class LlmClient
  def self.ask(prompt)
    chat = RubyLLM.chat
    chat.ask(prompt).content
  end
end
