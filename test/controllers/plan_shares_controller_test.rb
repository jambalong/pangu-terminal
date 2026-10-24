require "test_helper"

class PlanSharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "shares@example.com", password: "password123")
    @plan = Plan.create!(user: @user, subject: Weapon.first, plan_data: { "input" => {}, "output" => {} })
    sign_in @user
  end

  test "requires an owner: someone else's plan is a 404 for every action" do
    stranger = User.create!(email: "shares_stranger@example.com", password: "password123")
    theirs = Plan.create!(user: stranger, subject: Weapon.second, plan_data: { "input" => {}, "output" => {} })

    get plan_share_path(theirs)
    assert_response :not_found
    post plan_share_path(theirs)
    assert_response :not_found
    delete plan_share_path(theirs)
    assert_response :not_found
    assert_not theirs.reload.shared?
  end

  test "an unknown plan is a 404" do
    get plan_share_path(plan_id: 0)

    assert_response :not_found
  end

  test "the dialog offers to create a link when the plan is not shared" do
    get plan_share_path(@plan)

    assert_response :ok
    assert_select "[role=dialog]"
    assert_select "h2", text: "Share #{@plan.subject.name}"
    assert_select "button", text: "Create link"
    assert_select "input[readonly]", count: 0
  end

  test "creating the link redirects back to the dialog showing it" do
    post plan_share_path(@plan)

    assert_redirected_to plan_share_path(@plan)
    assert @plan.reload.shared?

    follow_redirect!
    assert_select "input#share-url[readonly][value=?]", "https://panguterminal.ambalong.dev/p/#{@plan.share_token}"
    assert_select "label[for=share-url]"
    assert_select "[role=status]"
    assert_select "button", text: "Copy link"
    assert_select "button", text: "Stop sharing"
  end

  test "the link uses the canonical host whatever host was requested" do
    host! "pangu-terminal.onrender.com"
    @plan.share!

    get plan_share_path(@plan)

    assert_select "input#share-url[value^='https://panguterminal.ambalong.dev/p/']"
  end

  test "creating twice keeps one link" do
    post plan_share_path(@plan)
    token = @plan.reload.share_token
    post plan_share_path(@plan)

    assert_equal token, @plan.reload.share_token
  end

  test "stopping sharing removes the token" do
    @plan.share!

    delete plan_share_path(@plan)

    assert_redirected_to plan_share_path(@plan)
    assert_not @plan.reload.shared?
  end

  test "guests can share their own plans" do
    sign_out @user
    get plans_path
    token = cookies[:guest_token]
    guest_plan = Plan.create!(guest_token: token, subject: Weapon.first, plan_data: { "input" => {}, "output" => {} })

    post plan_share_path(guest_plan)

    assert guest_plan.reload.shared?
  end

  test "a guest cannot share a signed-in user's plan" do
    sign_out @user

    post plan_share_path(@plan)

    assert_response :not_found
    assert_not @plan.reload.shared?
  end

  test "the planner shows a Share link and marks shared plans" do
    get plans_path
    assert_select "a[href=?]", plan_share_path(@plan), text: "Share"
    assert_select ".shared-badge", count: 0

    @plan.share!
    get plans_path
    assert_select ".shared-badge", text: "Shared"
  end
end
