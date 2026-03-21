require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
  SimpleCov.use_merging true
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Seeds static game data (Materials, cost tables, etc.) once per parallel worker.
    # Each worker runs in a forked process with its own database, so seeding must
    # happen here rather than in a one-time setup.
    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"

      original = $stdout
      $stdout = File.open(File::NULL, "w")
      Rails.application.load_seed
      $stdout = original
    end

    parallelize_teardown do |worker|
      SimpleCov.result
    end

    # Skip eager inventory seeding in tests. In production, initialize_inventory
    # bulk-inserts a row for every Material when a User is created. In tests,
    # that overhead is unnecessary and inventory rows are created on demand via
    # inventory_item_for(material) when a test needs a specific quantity.
    setup do
      User.skip_callback(:create, :after, :initialize_inventory)
    end

    teardown do
      User.set_callback(:create, :after, :initialize_inventory)
    end
  end
end
