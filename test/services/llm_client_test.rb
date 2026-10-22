require "test_helper"
class LlmClientTest < ActiveSupport::TestCase
  FakeChat = Struct.new(:response) do
    def ask(_prompt)
      raise response if response.is_a?(Exception)
      Struct.new(:content).new(response)
    end
  end

  # minitest/mock is not available, so swap RubyLLM.chat by hand.
  def with_chat(fake)
    original = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) { |*| fake }
    yield
  ensure
    RubyLLM.define_singleton_method(:chat, original)
  end

  test "returns the model response" do
    with_chat(FakeChat.new("Hit the forgery first.")) do
      assert_equal "Hit the forgery first.", LlmClient.real_ask("prompt")
    end
  end

  test "falls back on rate limit and timeout errors" do
    [ RubyLLM::RateLimitError.new("slow down"), Timeout::Error.new ].each do |error|
      with_chat(FakeChat.new(error)) do
        assert_equal LlmClient::FALLBACK_MESSAGE, LlmClient.real_ask("prompt")
      end
    end
  end

  test "falls back and logs on unexpected errors" do
    logged = StringIO.new
    original = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(logged)
    with_chat(FakeChat.new(RuntimeError.new("boom"))) do
      assert_equal LlmClient::FALLBACK_MESSAGE, LlmClient.real_ask("prompt")
    end
    assert_includes logged.string, "RuntimeError boom"
  ensure
    Rails.logger = original
  end

  test "fallback? recognises only the fallback message" do
    assert LlmClient.fallback?(LlmClient::FALLBACK_MESSAGE)
    assert_not LlmClient.fallback?("Farm the Forgery Challenge.")
  end
end
