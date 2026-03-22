require "test_helper"

class PlansControllerIndexTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "plans_index@example.com", password: "password123")
  end

  test "authenticated user can access index" do
    sign_in @user
    get plans_path
    assert_response :ok
  end

  test "guest can access index" do
    get plans_path
    assert_response :ok
  end
end

class PlansControllerNewTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "plans_new@example.com", password: "password123")
    sign_in @user
  end

  test "step 1 renders successfully" do
    get new_plan_path(step: 1)
    assert_response :ok
  end

  test "step 2 loads subjects list for valid subject type" do
    get new_plan_path(step: 2, subject_type: "Weapon")
    assert_response :ok
  end

  test "step 2 renders successfully with existing plans" do
    weapon = Weapon.find_by!(name: "Kumokiri")
    Plan.create!(
      user: @user,
      subject: weapon,
      plan_data: { "input" => {}, "output" => {} }
    )

    get new_plan_path(step: 2, subject_type: "Weapon")

    assert_response :ok
  end

  test "step 3 loads subject and builds form" do
    weapon = Weapon.find_by!(name: "Kumokiri")
    get new_plan_path(step: 3, subject_type: "Weapon", subject_id: weapon.id)
    assert_response :ok
  end

  test "invalid subject type renders successfully with errors" do
    get new_plan_path(step: 2, subject_type: "Character"),
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :ok
  end
end

class PlansControllerCreateTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "plans_create@example.com", password: "password123")
    @weapon = Weapon.find_by!(name: "Kumokiri")
  end

  test "creates plan and redirects on HTML success" do
    sign_in @user

    assert_difference "Plan.count", 1 do
      post plans_path, params: { plan: weapon_params }
    end

    assert_redirected_to plans_path
  end

  test "creates plan and returns turbo stream success on success" do
    sign_in @user

    assert_difference "Plan.count", 1 do
      post plans_path,
        params: { plan: weapon_params },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :ok
  end

  test "guest can create a plan" do
    assert_difference "Plan.count", 1 do
      post plans_path, params: { plan: weapon_params }
    end

    assert_redirected_to plans_path
  end

  test "renders error when subject is missing" do
    sign_in @user

    assert_no_difference "Plan.count" do
      post plans_path,
        params: { plan: weapon_params.merge(subject_id: 0) },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :ok
  end

  test "renders errors on duplicate path" do
    sign_in @user
    Plan.create!(
      user: @user,
      subject: @weapon,
      plan_data: { "input" => {}, "output" => {} }
    )

    assert_no_difference "Plan.count" do
      post plans_path,
        params: { plan: weapon_params },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :ok
  end

  test "renders error on planner validation error" do
    sign_in @user

    assert_no_difference "Plan.count" do
      post plans_path,
        params: { plan: weapon_params.merge(current_level: 90, target_level: 1) },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :ok
  end

  private

  def weapon_params
    {
      subject_type: "Weapon",
      subject_id: @weapon.id,
      current_level: 1,
      target_level: 20,
      current_ascension_rank: 0,
      target_ascension_rank: 1
    }
  end
end

class PlansControllerEditTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "plans_edit@example.com", password: "password123")
    @other_user = User.create!(email: "plans_edit_other@example.com", password: "password123")
    @weapon = Weapon.find_by!(name: "Kumokiri")
    @plan = Plan.create!(
      user: @user,
      subject: @weapon,
      plan_data: {
        "input" => {
          "current_level" => 1, "target_level" => 20,
          "current_ascension_rank" => 0, "target_ascension_rank" => 1
        },
        "output" => {}
      }
    )
  end

  test "owner can access edit" do
    sign_in @user
    get edit_plan_path(@plan)

    assert_response :ok
  end

  test "non-owner gets 404" do
    sign_in @other_user
    get edit_plan_path(@plan)

    assert_response :not_found
  end
end

class PlansControllerUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "plans_update@example.com", password: "password123")
    @other_user = User.create!(email: "plans_update_other@example.com", password: "password123")
    @weapon = Weapon.find_by!(name: "Kumokiri")
    @plan = Plan.create!(
      user: @user,
      subject: @weapon,
      plan_data: {
        "input" => {
          "current_level" => 1, "target_level" => 20,
          "current_ascension_rank" => 0, "target_ascension_rank" => 1
        },
        "output" => {}
      }
    )
  end

  test "owner can update plan and is redirected" do
    sign_in @user
    patch plan_path(@plan), params: { plan: update_params }

    assert_redirected_to plans_path
  end

  test "owner can update plan via turbo stream" do
    sign_in @user
    patch plan_path(@plan),
      params: { plan: update_params },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :ok
  end

  test "non-owner gets 404" do
    sign_in @other_user
    patch plan_path(@plan), params: { plan: update_params }

    assert_response :not_found
  end

  test "renders error on validation error" do
    sign_in @user
    original_plan_data = @plan.plan_data

    patch plan_path(@plan),
      params: { plan: update_params.merge(current_level: 90, target_level: 1) },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_equal original_plan_data, @plan.reload.plan_data
  end

  private

  def update_params
    {
      subject_type: "Weapon",
      subject_id: @weapon.id,
      current_level: 1,
      target_level: 40,
      current_ascension_rank: 0,
      target_ascension_rank: 2
    }
  end
end

class PlansControllerDestroyTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "plans_destroy@example.com", password: "password123")
    @other_user = User.create!(email: "plans_destroy_other@example.com", password: "password123")
    @weapon = Weapon.find_by!(name: "Kumokiri")
    @plan = Plan.create!(
      user: @user,
      subject: @weapon,
      plan_data: { "input" => {}, "output" => {} }
    )
  end


  test "owner can delete plan and is redirected" do
    sign_in @user

    assert_difference "Plan.count", -1 do
      delete plan_path(@plan)
    end

    assert_redirected_to plans_path
  end

  test "owner can delete plan via turbo streams" do
    sign_in @user

    assert_difference "Plan.count", -1 do
      delete plan_path(@plan),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :ok
  end

  test "non-owner gets 404" do
    sign_in @other_user

    assert_no_difference "Plan.count" do
      delete plan_path(@plan)
    end

    assert_response :not_found
  end

  test "confirm_delete renders for owner" do
    sign_in @user
    get confirm_delete_plan_path(@plan)
    assert_response :ok
  end

  test "confirm_delete returns 404 for non-owner" do
    sign_in @other_user
    get confirm_delete_plan_path(@plan)
    assert_response :not_found
  end
end
