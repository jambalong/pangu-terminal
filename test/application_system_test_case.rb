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

  setup do
    original = $stdout
    $stdout = File.open(File::NULL, "w")
    Rails.application.load_seed
    $stdout = original
  end
end
