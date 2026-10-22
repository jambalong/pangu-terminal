# Generates Farming Advisor advice off the request thread and caches it.
# FarmingAdviceRequest enqueues it once per prompt and the optimizer page polls
# until the advice (or a short-lived failure marker) shows up in the cache.
class FarmingAdviceJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(user_id, plan_id)
    user = User.find(user_id)
    plan = user.plans.find(plan_id)
    advisor = FarmingAdvisorService.for(user: user, plan: plan)
    return unless advisor.advisable?

    begin
      response = advisor.generate
      Rails.cache.write(advisor.failed_key, true, expires_in: FarmingAdviceRequest::FAILED_TTL) if LlmClient.fallback?(response)
    ensure
      Rails.cache.delete(advisor.pending_key)
    end
  end
end
