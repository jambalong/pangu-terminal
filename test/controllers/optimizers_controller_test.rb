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
    assert_equal [ @plan.id.to_s ], session[:optimizer_plan_ids]
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
    assert_equal [ @plan.id.to_s ], session[:optimizer_plan_ids]
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

    assert_enqueued_with(job: FarmingAdviceJob, args: [ @user.id, [ @plan.id ] ]) do
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

class OptimizersControllerSelectionTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = User.create!(email: "selection@example.com", password: "password123", sol3_phase: 3)
    @shell_credit = Material.find_by!(name: "Shell Credit")
    kumokiri, other_weapon = Weapon.where(name: "Kumokiri").to_a + Weapon.where.not(name: "Kumokiri").limit(1).to_a
    @plan_a = Plan.create!(user: @user, subject: kumokiri,
                           plan_data: { "input" => {}, "output" => { @shell_credit.id.to_s => 25480 } })
    @plan_b = Plan.create!(user: @user, subject: other_weapon,
                           plan_data: { "input" => {}, "output" => { @shell_credit.id.to_s => 1000 } })
    @stranger = User.create!(email: "selection_stranger@example.com", password: "password123")
    @foreign = Plan.create!(user: @stranger, subject: kumokiri, plan_data: { "input" => {}, "output" => {} })
    sign_in @user
  end

  def select_all
    post optimizer_select_plan_path, params: { all: 1 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  test "all plans can be selected and the card says so" do
    select_all

    assert_response :ok
    assert_includes response.body, "All plans (2)"
  end

  test "all plans stays dynamic: a plan created later is included" do
    select_all
    third = Plan.create!(user: @user, subject: Weapon.where.not(id: [ @plan_a.subject_id, @plan_b.subject_id ]).first,
                         plan_data: { "input" => {}, "output" => {} })

    get optimizer_path

    assert_includes response.body, "All plans (3)"
    assert third.persisted?
  end

  test "a chosen set of plans is stored and shown" do
    post optimizer_select_plan_path, params: { plan_ids: [ @plan_a.id, @plan_b.id ] },
                                     headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal [ @plan_a.id.to_s, @plan_b.id.to_s ], session[:optimizer_plan_ids]
    assert_includes response.body, "2 plans"
  end

  test "selecting a chosen set clears all-plans mode" do
    select_all
    post optimizer_select_plan_path, params: { plan_ids: [ @plan_a.id ] }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    get optimizer_path
    assert_not_includes response.body, "All plans"
    assert_includes response.body, @plan_a.subject.name
  end

  test "someone else's plan ids are ignored, not an error" do
    post optimizer_select_plan_path, params: { plan_ids: [ @foreign.id ] }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :ok
    assert_includes response.body, "SELECT A PLAN"
  end

  test "malformed selection params are harmless" do
    post optimizer_select_plan_path, params: { plan_ids: { "0" => "x" }, plan_id: [ "a" ] },
                                     headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :ok
  end

  test "running with all plans shows the combined deficit" do
    select_all
    get optimizer_path, params: { run: 1 }

    assert_response :ok
    assert_select ".optimizer-metrics"
  end

  test "advice for all plans enqueues one job covering every plan" do
    select_all
    get optimizer_path

    assert_enqueued_with(job: FarmingAdviceJob, args: [ @user.id, [ @plan_a.id, @plan_b.id ] ]) do
      get optimizer_advise_path
    end
  end

  test "the chooser lists plans as checkboxes inside a labelled group, pre-checked for the current set" do
    post optimizer_select_plan_path, params: { plan_ids: [ @plan_a.id ] }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    get optimizer_plans_modal_path

    assert_select "fieldset legend"
    assert_select "input[type=checkbox][name='plan_ids[]']", count: 2
    assert_select "input[type=checkbox][value='#{@plan_a.id}'][checked]"
    assert_select "input[type=checkbox][value='#{@plan_b.id}'][checked]", count: 0
    assert_select "button", text: "Use all plans (2)"
  end

  test "the chooser never lists another user's plans" do
    get optimizer_plans_modal_path

    assert_select "input[value='#{@foreign.id}']", count: 0
  end
end
