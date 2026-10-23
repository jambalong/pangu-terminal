require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET / returns success" do
    get root_path
    assert_response :success
  end

  test "GET /privacy returns success without signing in" do
    get privacy_path
    assert_response :success
    assert_select "h1", text: "Privacy Policy"
  end

  test "GET /user-manual returns success" do
    get user_manual_path
    assert_response :success
  end
end
