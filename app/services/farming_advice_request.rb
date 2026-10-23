# Serves Farming Advisor advice without holding a web thread on the LLM call.
#
#   [:ready, text]   advice is cached, show it
#   [:pending, nil]  a job is generating it, poll again
#   [:failed, text]  the last attempt fell back; show the fallback briefly
#   [:none, nil]     nothing to advise on (no deficits)
#   [:limited, text] the daily generation budget is spent; show the notice
#
# The first request after a cache miss enqueues FarmingAdviceJob and marks it
# pending; further requests while it runs do not enqueue again. Each new
# generation costs an LLM call, so it is counted against a per-user and an
# overall daily budget (cached advice and repeat polls are free).
class FarmingAdviceRequest
  PENDING_TTL = 90.seconds
  FAILED_TTL = 30.seconds
  LIMIT_MESSAGE = "You have reached today's Farming Advisor limit. The numbers above are unaffected; try the advisor again tomorrow."

  def self.user_daily_limit = ENV.fetch("ADVISOR_DAILY_LIMIT_PER_USER", 20).to_i

  def self.global_daily_limit = ENV.fetch("ADVISOR_DAILY_LIMIT_GLOBAL", 500).to_i

  def initialize(user:, plan:)
    @user = user
    @plan = plan
  end

  def fetch
    advisor = FarmingAdvisorService.for(user: @user, plan: @plan)
    return [ :none, nil ] unless advisor.advisable?

    if (advice = advisor.cached_advice)
      [ :ready, advice ]
    elsif Rails.cache.read(advisor.failed_key)
      [ :failed, LlmClient::FALLBACK_MESSAGE ]
    elsif Rails.cache.read(advisor.pending_key)
      [ :pending, nil ]
    elsif budget_spent?
      [ :limited, LIMIT_MESSAGE ]
    else
      enqueue(advisor)
      [ :pending, nil ]
    end
  end

  private

  def enqueue(advisor)
    Rails.cache.write(advisor.pending_key, true, expires_in: PENDING_TTL)
    spend_budget
    FarmingAdviceJob.perform_later(@user.id, @plan.id)
  end

  def budget_spent?
    Rails.cache.read(user_budget_key).to_i >= self.class.user_daily_limit ||
      Rails.cache.read(global_budget_key).to_i >= self.class.global_daily_limit
  end

  # A soft cap: the read-then-write is not atomic, so a burst may overshoot by a
  # request or two, which is fine for cost protection.
  def spend_budget
    [ user_budget_key, global_budget_key ].each do |key|
      Rails.cache.write(key, Rails.cache.read(key).to_i + 1, expires_in: 1.day)
    end
  end

  def user_budget_key = "advisor_budget/user/#{@user.id}/#{Date.current}"

  def global_budget_key = "advisor_budget/global/#{Date.current}"
end
