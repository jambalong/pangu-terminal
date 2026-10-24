require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Rails registers the Cuprite driver itself from these options (a separate
  # Capybara.register_driver block would be overridden). The 30s process_timeout
  # covers a cold CI runner starting Chrome (Ferrum's default is 10s);
  # no-sandbox lets Chrome run as root in containers.
  driven_by :cuprite,
    screen_size: [ 1400, 1400 ],
    options: {
      headless: true,
      process_timeout: 30,
      browser_options: { "no-sandbox": nil }
    }

  # Runs axe-core (vendored in test/support, MPL-2.0) against the current page
  # and fails with a readable list. Pass rule ids to skip while they are fixed.
  AXE_SOURCE = File.read(Rails.root.join("test/support/axe.min.js"), encoding: "UTF-8")

  def assert_no_axe_violations(skip: [])
    browser = page.driver.browser
    browser.execute(AXE_SOURCE)
    options = { rules: skip.index_with { { enabled: false } } }.to_json
    json = browser.evaluate_async(<<~JS, 30)
      axe.run(document, #{options}).then((results) => __f(JSON.stringify(results.violations.map((v) => ({
        id: v.id, impact: v.impact, help: v.help, targets: v.nodes.slice(0, 3).map((n) => n.target.join(" "))
      })))))
    JS
    violations = JSON.parse(json)
    message = violations.map { |v| "[#{v["impact"]}] #{v["id"]}: #{v["help"]} (#{v["targets"].join(", ")})" }.join("\n")
    assert_empty violations, "Accessibility violations on #{current_path}:\n#{message}"
  end

  setup do
    original = $stdout
    $stdout = File.open(File::NULL, "w")
    Rails.application.load_seed
    $stdout = original
  end
end
