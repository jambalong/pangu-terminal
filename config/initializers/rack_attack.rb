class Rack::Attack
  ### Cache ###
  # Uses Rails.cache by default. Overridden per test in RateLimitingTest
  # to an isolated MemoryStore so throttle counts accumulate without
  # affecting other tests.
  #
  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### General IP Throttle ###
  # Catches malicious clients or misconfigured scrapers hitting the whole app.
  # 300 requests per 5 minutes is the rack-attack recommended default.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip # unless req.path.start_with?('/assets')
  end

  ### Brute Force Login Protection ###
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/sign-in" && req.post?
  end

  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/sign-in" && req.post?
      req.params["user"]&.dig("email").to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  ### API Token Throttle ###
  # Scoped to /api/ routes only. Keyed by token so each API consumer
  # gets their own bucket, so one abusive client can't affect others.
  throttle("api/token", limit: 60, period: 1.minute) do |req|
    if req.start_with?("/api")
      req.get_header("HTTP_AUTHORIZATION")&.delete_prefix("Bearer ")
    end
  end

  ### Throttle Response ###
  # Override default response to return JSON for API routes,
  # plain text for everything else.
  self.throttled_responder = lambda do |req|
    if req.path.start_with?("/api/")
      [ 429, { "Content-Type" => "application/json" },
            [ { error: "Rate limit exceeded. Try again later." }.to_json ] ]
    else
      [ 429, { "Content-Type" => "text/plain" },
            [ "Rate limit exceeded. Try again later." ] ]
    end
  end
end
