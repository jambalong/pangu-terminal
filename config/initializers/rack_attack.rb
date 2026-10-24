class Rack::Attack
  ### Cache ###
  # Uses Rails.cache by default. Overridden per test in RateLimitingTest
  # to an isolated MemoryStore so throttle counts accumulate without
  # affecting other tests.
  #
  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Health Check Safelist ###
  # Render's health check and any uptime monitor hit /up constantly. Throttle
  # counters are stored in Rails.cache (Solid Cache, so the database), and a
  # database write on every ping would keep the free Neon compute awake around
  # the clock and burn its monthly compute hours. /up returns no data and does
  # no work, so it needs no throttling.
  safelist("health check") do |req|
    req.path == "/up"
  end

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

  ### Account and Plan Creation Throttles ###
  # Guests can create plans without an account, so one client could otherwise
  # fill the database by dropping its cookie. The sign-up form only exists as a
  # fallback while no OAuth provider is configured.
  throttle("plans/create/ip", limit: 60, period: 1.hour) do |req|
    req.ip if req.path == "/app/planner" && req.post?
  end

  throttle("imports/ip", limit: 20, period: 1.hour) do |req|
    req.ip if req.path == "/app/inventory/import" && req.post?
  end

  throttle("signups/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/signup" && req.post?
  end

  ### OAuth Throttle ###
  # Covers the request and callback phases under /users/auth/. A normal sign-in
  # is two hits (POST to start, GET callback), so 20 a minute is generous.
  throttle("oauth/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/users/auth/")
  end

  ### API Token Throttle ###
  # Scoped to /api/ routes only. Keyed by token so each API consumer
  # gets their own bucket, so one abusive client can't affect others.
  throttle("api/token", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api")
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
