require "test_helper"

class FarmingAdviceRequestTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include MemoryCacheTestHelper

  setup do
    @user = User.create!(email: "advice_request@example.com", password: "password123", sol3_phase: 3)
    @shell_credit = Material.find_by!(name: "Shell Credit")
    @plan = Plan.create!(
      user: @user,
      subject: Weapon.find_by!(name: "Kumokiri"),
      plan_data: { "input" => {}, "output" => { @shell_credit.id => 25480 } }
    )
    @request = FarmingAdviceRequest.new(user: @user, plan: @plan)
    @advisor = FarmingAdvisorService.for(user: @user, plan: @plan)
  end

  test "is pending and enqueues the job on a cache miss" do
    assert_enqueued_with(job: FarmingAdviceJob, args: [ @user.id, @plan.id ]) do
      assert_equal [ :pending, nil ], @request.fetch
    end
    assert Rails.cache.read(@advisor.pending_key)
  end

  test "does not enqueue a second job while one is pending" do
    @request.fetch

    assert_no_enqueued_jobs { assert_equal [ :pending, nil ], @request.fetch }
  end

  test "enqueues again once the pending marker has expired" do
    @request.fetch
    Rails.cache.delete(@advisor.pending_key)

    assert_enqueued_jobs 1 do
      @request.fetch
    end
  end

  test "returns cached advice without enqueueing" do
    Rails.cache.write(@advisor.cache_key, "Hit the forgery first.")

    assert_no_enqueued_jobs do
      assert_equal [ :ready, "Hit the forgery first." ], @request.fetch
    end
  end

  test "returns the fallback while a failed marker is live and does not enqueue" do
    Rails.cache.write(@advisor.failed_key, true)

    assert_no_enqueued_jobs do
      assert_equal [ :failed, LlmClient::FALLBACK_MESSAGE ], @request.fetch
    end
  end

  test "returns none when the plan has no deficits" do
    @user.inventory_item_for(@shell_credit).update!(quantity: 25480)

    assert_no_enqueued_jobs { assert_equal [ :none, nil ], @request.fetch }
  end

  test "the advice changes key when the inventory changes" do
    before = @advisor.cache_key
    @user.inventory_item_for(@shell_credit).update!(quantity: 100)

    assert_not_equal before, FarmingAdvisorService.for(user: @user, plan: @plan).cache_key
  end
end
