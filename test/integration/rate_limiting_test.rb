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
  end

  test "returns 429 after exceeding API rate limit" do
    61.times do
      get api_v1_inventory_index_path, headers: { "Authorization" => "Bearer #{@raw_token}" }
    end

    assert_response :too_many_requests
    json = JSON.parse(response.body)
    assert_equal "Rate limit exceeded. Try again later.", json["error"]
  end

  test "returns 429 after exceeding the OAuth throttle" do
    21.times { get "/users/auth/unknown" }

    assert_response :too_many_requests
  end

  test "the legacy sign-in form is still throttled per email" do
    6.times do
      post user_session_path, params: { user: { email: "victim@example.com", password: "nope" } }, headers: { "REMOTE_ADDR" => "10.0.0.#{rand(200)}" }
    end

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
