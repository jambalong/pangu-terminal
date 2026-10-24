require "test_helper"

class SharedPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "shared_owner@example.com", password: "password123", display_name: "secret-owner")
    @shell = Material.find_by!(name: "Shell Credit")
    @core = Material.find_by!(name: "Basic Energy Core")
    @plan = Plan.create!(user: @user, subject: Weapon.find_by!(name: "Kumokiri"),
                         plan_data: { "input" => { "target_level" => 90 }, "output" => { @shell.id.to_s => 25480, @core.id.to_s => 38 } })
    @token = @plan.share!
  end

  test "anyone can see a shared plan without signing in" do
    get shared_plan_path(@token)

    assert_response :ok
    assert_select "h1", text: "Kumokiri"
    assert_select ".shared-plan-material", count: 2
    assert_select ".shared-plan-material-name", text: "Shell Credit"
    assert_select ".shared-plan-material-qty", text: "25,480"
    assert_select "a", text: "Try Pangu Terminal"
  end

  test "it shows no owner details" do
    get shared_plan_path(@token)

    assert_not_includes response.body, @user.email
    assert_not_includes response.body, "secret-owner"
    assert_not_includes response.body, @user.id.to_s + "/"
    assert_select ".user-badge", count: 0
  end

  test "it is not indexed, not cached, and carries link preview tags" do
    get shared_plan_path(@token)

    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
    assert_match(/no-cache|no-store|max-age=0/, response.headers["Cache-Control"])
    assert_select "meta[name=robots][content='noindex, nofollow']"
    assert_select "title", text: "Kumokiri plan on Pangu Terminal"
    assert_select "meta[property='og:title'][content='Kumokiri plan on Pangu Terminal']"
    assert_select "meta[name=description][content*='2 kinds']"
  end

  test "an unknown or malformed token is a 404" do
    get shared_plan_path("A" * 22)
    assert_response :not_found

    get "/p/short"
    assert_response :not_found

    get "/p/#{'x' * 100}"
    assert_response :not_found
  end

  test "stopping sharing kills the link" do
    @plan.unshare!

    get shared_plan_path(@token)

    assert_response :not_found
  end

  test "deleting the plan kills the link" do
    @plan.destroy

    get shared_plan_path(@token)

    assert_response :not_found
  end

  test "editing the plan is reflected on the shared page" do
    @plan.update!(plan_data: { "input" => {}, "output" => { @shell.id.to_s => 1 } })

    get shared_plan_path(@token)

    assert_select ".shared-plan-material", count: 1
    assert_select ".shared-plan-material-qty", text: "1"
  end

  test "a plan with no materials says so" do
    @plan.update_columns(plan_data: { "input" => {}, "output" => {} })

    get shared_plan_path(@token)

    assert_select ".shared-plan-empty"
  end

  test "it never shows other plans of the same owner" do
    other = Plan.create!(user: @user, subject: Weapon.where.not(id: @plan.subject_id).first, plan_data: { "input" => {}, "output" => {} })

    get shared_plan_path(@token)

    assert_not_includes response.body, other.subject.name
  end

  test "a signed-in visitor sees the same page and a guest plan can be shared too" do
    sign_in User.create!(email: "shared_visitor@example.com", password: "password123")
    guest_plan = Plan.create!(guest_token: SecureRandom.uuid, subject: Weapon.second, plan_data: { "input" => {}, "output" => {} })
    guest_token = guest_plan.share!

    get shared_plan_path(@token)
    assert_response :ok
    get shared_plan_path(guest_token)
    assert_response :ok
  end

  test "a shared plan whose subject is gone is a 404, not an error" do
    @plan.update_columns(subject_id: 0)

    get shared_plan_path(@token)

    assert_response :not_found
  end

  test "robots.txt keeps shared pages out of search" do
    assert_includes Rails.root.join("public/robots.txt").read, "Disallow: /p/"
  end
end
