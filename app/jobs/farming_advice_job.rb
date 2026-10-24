# Generates Farming Advisor advice off the request thread and caches it.
# FarmingAdviceRequest enqueues it once per prompt and the optimizer page polls
# until the advice (or a short-lived failure marker) shows up in the cache.
class FarmingAdviceJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  # plan_ids is an array (an integer from an older enqueue is accepted too).
  def perform(user_id, plan_ids)
    user = User.find(user_id)
    plans = user.plans.by_priority.where(id: Array(plan_ids)).to_a
    raise ActiveRecord::RecordNotFound, "no plans to advise on" if plans.empty?

    advisor = FarmingAdvisorService.for(user: user, plans: plans)
    return unless advisor.advisable?

    begin
      response = advisor.generate
      Rails.cache.write(advisor.failed_key, true, expires_in: FarmingAdviceRequest::FAILED_TTL) if LlmClient.fallback?(response)
    ensure
      Rails.cache.delete(advisor.pending_key)
    end
  end
end
