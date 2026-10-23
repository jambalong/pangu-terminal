class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "dashboard@example.com", password: "password123")
  end

  test "redirects unauthenticated user to sign in" do
    get authenticated_root_path
    assert_redirected_to new_user_session_path
  end

  test "returns 200 for authenticated user" do
    sign_in @user
    get authenticated_root_path
    assert_response :ok
  end

  test "a new account sees the getting started checklist" do
    sign_in @user
    get authenticated_root_path

    assert_select ".onboarding-card"
    assert_select ".onboarding-step", count: 3
    assert_select ".onboarding-step.is-done", count: 0
  end

  test "finished steps are marked and the card goes away when all are done" do
    @user.update!(sol3_phase: 3)
    sign_in @user
    get authenticated_root_path
    assert_select ".onboarding-step.is-done", count: 1

    Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"), plan_data: { "input" => {}, "output" => {} })
    @user.inventory_item_for(Material.find_by!(name: "Shell Credit")).update!(quantity: 1)
    get authenticated_root_path
    assert_select ".onboarding-card", count: 0
  end
end
