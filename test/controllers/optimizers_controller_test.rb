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
    @user = User.create!(email: "optimizer_select@example.com", password: "password123")
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
