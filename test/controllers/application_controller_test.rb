require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "sync@example.com", password: "password123")
    @weapon = Weapon.find_by!(name: "Kumokiri")
  end

  test "sign in redirects to dashboard" do
    post user_session_path, params: {
      user: { email: @user.email, password: @user.password }
    }

    assert_redirected_to authenticated_root_path
  end

  test "guest plans are migrated to user on sign in" do
    guest_token = SecureRandom.uuid

    guest_plan = Plan.create!(
      guest_token: guest_token,
      subject: @weapon,
      plan_data: { "input" => {}, "output" => {} }
    )

    cookies[:guest_token] = guest_token

    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }

    guest_plan.reload
    assert_equal @user.id, guest_plan.user_id
    assert_nil guest_plan.guest_token
  end

  test "duplicate guest plan are destroyed on sign in" do
    existing_plan = Plan.create!(
      user: @user,
      subject: @weapon,
      plan_data: { "input" => {}, "output" => {} }
    )

    guest_token = SecureRandom.uuid

    duplicate_guest_plan = Plan.create!(
      guest_token: guest_token,
      subject: @weapon,
      plan_data: { "input" => {}, "output" => {} }
    )

    cookies[:guest_token] = guest_token

    assert_difference "Plan.count", -1 do
      post user_session_path, params: {
        user: { email: @user.email, password: "password123" }
      }
    end

    assert_raises(ActiveRecord::RecordNotFound) { duplicate_guest_plan.reload }
    assert_nothing_raised { existing_plan.reload }
  end

  test "guest token cookie is cleared after sign in" do
    guest_token = SecureRandom.uuid

    Plan.create!(
      guest_token: guest_token,
      subject: @weapon,
      plan_data: { "input" => {}, "output" => {} }
    )

    cookies[:guest_token] = guest_token

    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }

    assert cookies[:guest_token].blank?
  end

  test "sign in without guest token does not affect plans" do
    Plan.create!(
      user: @user,
      subject: @weapon,
      plan_data: { "input" => {}, "output" => {} }
    )

    assert_no_difference "Plan.count" do
      post user_session_path, params: {
        user: { email: @user.email, password: "password123" }
      }
    end
  end

  test "sign out redirects to root" do
    sign_in @user
    delete destroy_user_session_path
    assert_redirected_to root_path
  end
end
