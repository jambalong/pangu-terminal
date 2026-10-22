require "simplecov"
require "simplecov-cobertura"

SimpleCov.start "rails" do
  enable_coverage :branch
  skip "/test/"
  SimpleCov.merging true
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ])
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Prevent real LLM API calls in tests
LlmClient.instance_eval do
  singleton_class.alias_method :real_ask, :ask # kept so LlmClient's own tests can exercise the real code

  def ask(prompt)
    "Stub farming advice."
  end
end

# The suite runs on :null_store. Include this to get a real in-memory cache for
# one test class (restored in teardown), for code that depends on cache hits.
module MemoryCacheTestHelper
  extend ActiveSupport::Concern

  included do
    setup do
      @original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
    end

    teardown { Rails.cache = @original_cache }
  end
end

# Replaces LlmClient.ask for the block (the suite stubs it globally already).
module LlmAskTestHelper
  def with_llm_response(response)
    original = LlmClient.method(:ask)
    LlmClient.define_singleton_method(:ask) { |_prompt| response }
    yield
  ensure
    LlmClient.define_singleton_method(:ask, original)
  end
end

module ActiveSupport
  class TestCase
    include Devise::Test::IntegrationHelpers

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
