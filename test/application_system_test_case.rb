require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Warden::Test::Helpers

  setup { Warden.test_mode! }
  teardown { Warden.test_reset! }

  # Signs a user in without the browser flow. The real OAuth round trip (button,
  # callback, account creation) is covered in OauthSignInTest and UserJourneyTest.
  def sign_in_as(user)
    login_as(user, scope: :user)
    visit authenticated_root_path
    assert_text "Dashboard"
  end

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
    # Measure after entry animations finish; mid-fade colors read as low contrast.
    20.times do
      break if page.evaluate_script("document.getAnimations().every((a) => a.playState !== 'running')")

      sleep 0.1
    end
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
end

# Seed the static game data once per process, outside any test transaction, so it
# persists across tests. Seeding in `setup` ran inside each test's transaction (it
# was rolled back every time) and re-`load`ed the seed files, which redefine their
# top-level constants and print an "already initialized constant" warning per test.
# The system suite is below the parallelization threshold, so `parallelize_setup`
# does not run for it.
original_stdout = $stdout
$stdout = File.open(File::NULL, "w")
begin
  Rails.application.load_seed
ensure
  $stdout.close
  $stdout = original_stdout
end
