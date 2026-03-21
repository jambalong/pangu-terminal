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
end
