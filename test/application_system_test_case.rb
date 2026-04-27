require "test_helper"
require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1400, 1400 ],
    browser_options: { "no-sandbox": nil },
    headless: true
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite

  setup do
      original = $stdout
      $stdout = File.open(File::NULL, "w")
      Rails.application.load_seed
      $stdout = original
    end
end
