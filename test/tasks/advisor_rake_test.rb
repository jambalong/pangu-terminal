require "test_helper"
require "rake"

class AdvisorRakeTest < ActiveSupport::TestCase
  setup do
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    load Rails.root.join("lib/tasks/advisor.rake") unless Rake::Task.task_defined?("advisor:check")
    Rake::Task["advisor:check"].reenable
  end

  def with_ask(response)
    original = LlmClient.method(:ask)
    LlmClient.define_singleton_method(:ask) { |_prompt| response }
    yield
  ensure
    LlmClient.define_singleton_method(:ask, original)
  end

  test "reports OK when the advisor answers" do
    with_ask("OK") do
      out, = capture_io { Rake::Task["advisor:check"].invoke }
      assert_includes out, "OK: OK"
    end
  end

  test "exits non-zero when the advisor falls back" do
    with_ask(LlmClient::FALLBACK_MESSAGE) do
      assert_raises(SystemExit) { capture_io { Rake::Task["advisor:check"].invoke } }
    end
  end
end
