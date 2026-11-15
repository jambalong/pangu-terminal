require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    # Throttles count in fixed windows; start at a window boundary so a burst of
    # requests can never straddle two windows and slip under the limit.
    travel_to Time.utc(2026, 1, 1, 0, 0, 1)
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    @user = User.create!(email: "ratelimit_#{SecureRandom.hex(4)}@example.com", password: "password123")
    @api_key = @user.api_keys.create!(name: "test key")
    @raw_token = @api_key.raw_token
  end

  teardown do
    travel_back
    Rack::Attack.cache.store = Rails.cache
  end

  test "returns 429 after exceeding API rate limit" do
    61.times do
      get api_v1_inventory_index_path, headers: { "Authorization" => "Bearer #{@raw_token}" }
    end

    assert_response :too_many_requests
    json = JSON.parse(response.body)
    assert_equal "Rate limit exceeded. Try again later.", json["error"]
  end

  test "the API throttle keys its cache entry by a digest, never the raw token" do
    get api_v1_inventory_index_path, headers: { "Authorization" => "Bearer #{@raw_token}" }

    keys = Rack::Attack.cache.store.instance_variable_get(:@data).keys
    api_keys = keys.select { |key| key.include?("api/token") }

    assert_equal 1, api_keys.size
    refute api_keys.any? { |key| key.downcase.include?(@raw_token.downcase) },
      "the raw token must not appear in the cache key (Solid Cache stores keys readably in the database)"
    assert api_keys.first.end_with?(":api/token:#{Digest::SHA256.hexdigest(@raw_token)}")
  end

  test "the API throttle counts each token separately" do
    other_raw_token = @user.api_keys.create!(name: "other key").raw_token

    61.times { get api_v1_inventory_index_path, headers: { "Authorization" => "Bearer #{@raw_token}" } }
    assert_response :too_many_requests

    get api_v1_inventory_index_path, headers: { "Authorization" => "Bearer #{other_raw_token}" }
    assert_response :ok
  end

  test "API requests without a token do not create an api/token counter" do
    get api_v1_inventory_index_path

    assert_response :unauthorized
    keys = Rack::Attack.cache.store.instance_variable_get(:@data).keys
    assert keys.none? { |key| key.include?("api/token") }
  end

  test "returns 429 after exceeding the OAuth throttle" do
    21.times { get "/users/auth/unknown" }

    assert_response :too_many_requests
  end

  test "returns 429 after too many plan creations from one IP" do
    61.times { post "/app/planner", params: {} }

    assert_response :too_many_requests
  end

  test "returns 429 after too many sign-ups from one IP" do
    6.times { post "/signup", params: { user: { email: "x@example.com", password: "password123" } } }

    assert_response :too_many_requests
  end

  test "health checks are never throttled or counted" do
    301.times { get rails_health_check_path }

    assert_response :ok
    assert_equal 0, Rack::Attack.cache.store.instance_variable_get(:@data).size,
      "/up must not write throttle counters (they live in the database in production)"
  end

  test "returns 429 after too many inventory imports from one IP" do
    21.times { post "/app/inventory/import", params: {} }

    assert_response :too_many_requests
  end

  test "returns 429 after too many shared-plan page requests from one IP" do
    61.times { get "/p/#{'a' * 22}" }

    assert_response :too_many_requests
  end
end
