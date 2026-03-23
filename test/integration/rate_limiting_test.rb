require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    @user = User.create!(email: "ratelimit_#{SecureRandom.hex(4)}@example.com", password: "password123")
    @api_key = @user.api_keys.create!(name: "test key")
    @raw_token = @api_key.raw_token
  end

  teardown do
    Rack::Attack.cache.store = Rails.cache
    Rack::Attack.reset!
  end

  test "returns 429 after exceeding API rate limit" do
    61.times do
      get api_v1_inventory_index_path, headers: { "Authorization" => "Bearer #{@raw_token}" }
    end

    assert_response :too_many_requests
    json = JSON.parse(response.body)
    assert_equal "Rate limit exceeded. Try again later.", json["error"]
  end
end
