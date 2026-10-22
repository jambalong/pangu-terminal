require "test_helper"

class FarmingAdviceJobTest < ActiveSupport::TestCase
  include MemoryCacheTestHelper
  include LlmAskTestHelper

  setup do
    @user = User.create!(email: "advice_job@example.com", password: "password123", sol3_phase: 3)
    shell_credit = Material.find_by!(name: "Shell Credit")
    @plan = Plan.create!(
      user: @user,
      subject: Weapon.find_by!(name: "Kumokiri"),
      plan_data: { "input" => {}, "output" => { shell_credit.id => 25480 } }
    )
    @advisor = FarmingAdvisorService.for(user: @user, plan: @plan)
  end

  test "generates the advice, caches it and clears the pending marker" do
    Rails.cache.write(@advisor.pending_key, true)

    FarmingAdviceJob.perform_now(@user.id, @plan.id)

    assert_equal "Stub farming advice.", @advisor.cached_advice
    assert_nil Rails.cache.read(@advisor.pending_key)
    assert_nil Rails.cache.read(@advisor.failed_key)
  end

  test "a fallback response is not cached and leaves a failed marker" do
    Rails.cache.write(@advisor.pending_key, true)

    with_llm_response(LlmClient::FALLBACK_MESSAGE) do
      FarmingAdviceJob.perform_now(@user.id, @plan.id)
    end

    assert_nil @advisor.cached_advice
    assert Rails.cache.read(@advisor.failed_key)
    assert_nil Rails.cache.read(@advisor.pending_key)
  end

  test "clears the pending marker even when the LLM call raises" do
    Rails.cache.write(@advisor.pending_key, true)

    with_llm_response(nil) do
      LlmClient.define_singleton_method(:ask) { |_prompt| raise "boom" }
      assert_raises(RuntimeError) { FarmingAdviceJob.perform_now(@user.id, @plan.id) }
    end

    assert_nil Rails.cache.read(@advisor.pending_key)
  end

  test "discards quietly when the plan no longer exists" do
    assert_nothing_raised { FarmingAdviceJob.perform_now(@user.id, 0) }
  end

  test "does nothing when there is nothing to advise on" do
    @plan.update!(plan_data: { "input" => {}, "output" => {} })

    assert_nothing_raised { FarmingAdviceJob.perform_now(@user.id, @plan.id) }
  end
end
