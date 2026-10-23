require "test_helper"

class OptimizersControllerIndexTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "optimizer@example.com", password: "password123", sol3_phase: 3)
    @weapon = Weapon.find_by!(name: "Kumokiri")
    @shell_credit = Material.find_by!(name: "Shell Credit")
    @basic_energy_core = Material.find_by!(name: "Basic Energy Core")
    @lf_whisperin_core = Material.find_by!(name: "LF Whisperin Core")

    @plan = Plan.create!(
      user: @user,
      subject: @weapon,
      plan_data: {
        "input" => {
          "current_level" => 1, "target_level" => 20,
          "current_ascension_rank" => 0, "target_ascension_rank" => 1
        },
        "output" => {
          @shell_credit.id => 25480,
          @basic_energy_core.id => 38,
          @lf_whisperin_core.id => 6
        }
      }
    )
  end

  test "unauthenticated user is redirected to sign in" do
    get optimizer_path
    assert_redirected_to new_user_session_path
  end

  test "authenticated user can access optimizer" do
    sign_in @user
    get optimizer_path
    assert_response :ok
  end

  test "loads plan from plan_id param and stores in session" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }

    assert_response :ok
    assert_equal @plan.id.to_s, session[:optimizer_plan_id].to_s
  end

  test "loads plan from session when no plan_id param" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }
    get optimizer_path

    assert_response :ok
  end

  test "computes optimizer results when plan is selected" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }

    assert_response :ok
  end

  test "no plan selected renders without results" do
    sign_in @user
    get optimizer_path

    assert_response :ok
  end

  test "with no plans it points to the planner instead of offering plan selection" do
    @plan.destroy
    sign_in @user
    get optimizer_path

    assert_select ".optimizer-hint", text: /you have none yet/
    assert_select ".optimizer-plan-card--empty", count: 0
  end

  test "warns that results assume an empty inventory" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }

    assert_select ".optimizer-hint", text: /inventory is empty/
  end

  test "no inventory warning once something is owned" do
    @user.inventory_item_for(@shell_credit).update!(quantity: 100)
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }

    assert_select ".optimizer-hint", text: /inventory is empty/, count: 0
  end
end

class OptimizersControllerPlansModalTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "optimizer_modal@example.com", password: "password123")
  end

  test "unauthenticated user is redirected to sign in" do
    get optimizer_plans_modal_path
    assert_redirected_to new_user_session_path
  end

  test "authenticated user can access plans modal" do
    sign_in @user
    get optimizer_plans_modal_path
    assert_response :ok
  end
end

class OptimizersControllerSelectPlanTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "optimizer_select@example.com", password: "password123", sol3_phase: 3)
    @weapon = Weapon.find_by!(name: "Kumokiri")

    @plan = Plan.create!(
      user: @user,
      subject: @weapon,
      plan_data: { "input" => {}, "output" => {} }
    )
  end

  test "unauthenticated user is redirected to sign in" do
    post optimizer_select_plan_path, params: { plan_id: @plan.id }
    assert_redirected_to new_user_session_path
  end

  test "sets session and assigns selected plan" do
    sign_in @user
    post optimizer_select_plan_path,
      params: { plan_id: @plan.id },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :ok
    assert_equal @plan.id.to_s, session[:optimizer_plan_id].to_s
  end
end

class OptimizersControllerAdviseTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include MemoryCacheTestHelper
  include LlmAskTestHelper

  setup do
    @user = User.create!(email: "optimizer_advise@example.com", password: "password123", sol3_phase: 3)
    @weapon = Weapon.find_by!(name: "Kumokiri")
    @shell_credit = Material.find_by!(name: "Shell Credit")
    @lf_whisperin_core = Material.find_by!(name: "LF Whisperin Core")

    @plan = Plan.create!(
      user: @user,
      subject: @weapon,
      plan_data: {
        "input" => {
          "current_level" => 1, "target_level" => 20,
          "current_ascension_rank" => 0, "target_ascension_rank" => 1
        },
        "output" => {
          @shell_credit.id => 25480,
          @lf_whisperin_core.id => 6
        }
      }
    )
  end

  test "unauthenticated user is redirected to sign in" do
    get optimizer_advise_path
    assert_redirected_to new_user_session_path
  end

  test "returns no content when no plan in session" do
    sign_in @user
    get optimizer_advise_path
    assert_response :no_content
  end

  test "first request answers pending and enqueues the job" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }

    assert_enqueued_with(job: FarmingAdviceJob, args: [ @user.id, @plan.id ]) do
      get optimizer_advise_path
    end

    assert_response :ok
    assert_select "[data-advisor-poll-target='pending']"
    assert_select ".optimizer-advisor-text", false
  end

  test "shows the limit notice when the daily advisor budget is spent" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }
    original = FarmingAdviceRequest.method(:user_daily_limit)
    FarmingAdviceRequest.define_singleton_method(:user_daily_limit) { 0 }

    assert_no_enqueued_jobs do
      get optimizer_advise_path
    end
    assert_select ".optimizer-advisor-text", text: FarmingAdviceRequest::LIMIT_MESSAGE
  ensure
    FarmingAdviceRequest.define_singleton_method(:user_daily_limit, original)
  end

  test "polling while the job is pending does not enqueue more jobs" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }
    get optimizer_advise_path

    assert_no_enqueued_jobs do
      get optimizer_advise_path
    end
    assert_select "[data-advisor-poll-target='pending']"
  end

  test "serves the advice once the job has run" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }
    get optimizer_advise_path
    perform_enqueued_jobs

    get optimizer_advise_path

    assert_response :ok
    assert_select ".optimizer-advisor-text", text: "Stub farming advice."
    assert_select "[data-advisor-poll-target='pending']", false
  end

  test "repeat visits are served from the cache without a job" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }
    get optimizer_advise_path
    perform_enqueued_jobs

    assert_no_enqueued_jobs do
      get optimizer_advise_path
      get optimizer_advise_path
    end
    assert_select ".optimizer-advisor-text", text: "Stub farming advice."
  end

  test "shows the fallback when the job could not get advice and stops polling" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }
    get optimizer_advise_path
    with_llm_response(LlmClient::FALLBACK_MESSAGE) { perform_enqueued_jobs }

    get optimizer_advise_path

    assert_select ".optimizer-advisor-text", text: LlmClient::FALLBACK_MESSAGE
    assert_select "[data-advisor-poll-target='pending']", false
  end

  test "returns ok with plan in session" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }
    get optimizer_advise_path
    assert_response :ok
  end
end

class OptimizersControllerWithoutSol3PhaseTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "optimizer_nophase@example.com", password: "password123")
    shell_credit = Material.find_by!(name: "Shell Credit")
    @plan = Plan.create!(
      user: @user,
      subject: Weapon.find_by!(name: "Kumokiri"),
      plan_data: { "input" => {}, "output" => { shell_credit.id => 25480 } }
    )
  end

  test "index with run=1 shows the phase gate instead of crashing" do
    sign_in @user

    get optimizer_path, params: { plan_id: @plan.id, run: 1 }

    assert_response :ok
    assert_select ".optimizer-gate"
  end

  test "advise returns no content instead of crashing" do
    sign_in @user
    get optimizer_path, params: { plan_id: @plan.id }

    get optimizer_advise_path

    assert_response :no_content
  end
end
