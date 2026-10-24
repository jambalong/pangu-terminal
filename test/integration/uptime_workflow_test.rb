require "test_helper"
require "yaml"

class UptimeWorkflowTest < ActiveSupport::TestCase
  WORKFLOW = Rails.root.join(".github/workflows/uptime.yml")

  setup { @workflow = YAML.safe_load(WORKFLOW.read) }

  test "runs on a schedule that keeps a 15 minute idle timeout from firing" do
    cron = @workflow.dig(true, "schedule", 0, "cron") || @workflow.dig("on", "schedule", 0, "cron")

    minutes = cron.match(%r{\A\*/(\d+) \* \* \* \*\z})&.captures&.first.to_i
    assert_includes 1..14, minutes, "cron #{cron.inspect} must fire at least every 14 minutes"
  end

  test "pings the health endpoint, not a page that touches the database" do
    steps = @workflow.dig("jobs", "ping", "steps").map { |step| step["run"] }.join(" ")

    assert_includes steps, "https://panguterminal.ambalong.dev/up"
    assert_includes steps, "--fail"
  end

  test "has no repository permissions" do
    assert_equal({}, @workflow["permissions"])
  end
end
