ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      original = $stdout
      $stdout = File.open(File::NULL, "w")
      Rails.application.load_seed
      $stdout = original
    end
  end
end
