# Serves Farming Advisor advice without holding a web thread on the LLM call.
#
#   [:ready, text]   advice is cached, show it
#   [:pending, nil]  a job is generating it, poll again
#   [:failed, text]  the last attempt fell back; show the fallback briefly
#   [:none, nil]     nothing to advise on (no deficits)
#
# The first request after a cache miss enqueues FarmingAdviceJob and marks it
# pending; further requests while it runs do not enqueue again.
class FarmingAdviceRequest
  PENDING_TTL = 90.seconds
  FAILED_TTL = 30.seconds

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
    else
      enqueue_once(advisor)
      [ :pending, nil ]
    end
  end

  private

  def enqueue_once(advisor)
    return if Rails.cache.read(advisor.pending_key)

    Rails.cache.write(advisor.pending_key, true, expires_in: PENDING_TTL)
    FarmingAdviceJob.perform_later(@user.id, @plan.id)
  end
end
