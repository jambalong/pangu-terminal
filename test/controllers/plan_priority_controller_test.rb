require "test_helper"

class PlanPriorityControllerTest < ActionDispatch::IntegrationTest
  STREAM = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    @user = User.create!(email: "priority_ctrl@example.com", password: "password123", sol3_phase: 3)
    @a, @b, @c = Weapon.limit(3).map do |weapon|
      Plan.create!(user: @user, subject: weapon, plan_data: { "input" => {}, "output" => {} })
    end
    sign_in @user
  end

  def order = @user.plans.by_priority.to_a

  test "the planner lists plans in priority order with their rank" do
    @a.update_columns(position: 3)
    @c.update_columns(position: 1)

    get plans_path

    titles = css_select(".plan-card-title").map { |node| node.text.squish }
    assert_equal [ "#{@c.subject.name} #1", "#{@b.subject.name} #2", "#{@a.subject.name} #3" ], titles
  end

  test "each card has labelled move buttons, disabled at the ends" do
    get plans_path

    buttons = css_select("button.plan-move").to_h { |node| [ node["aria-label"], node.key?("disabled") ] }

    assert_equal 6, buttons.size
    assert buttons["Move #{@a.subject.name} up, priority 1 of 3"], "first plan cannot go up"
    assert_not buttons["Move #{@a.subject.name} down, priority 1 of 3"]
    assert_not buttons["Move #{@b.subject.name} up, priority 2 of 3"]
    assert_not buttons["Move #{@b.subject.name} down, priority 2 of 3"]
    assert_not buttons["Move #{@c.subject.name} up, priority 3 of 3"]
    assert buttons["Move #{@c.subject.name} down, priority 3 of 3"], "last plan cannot go down"
  end

  test "a single plan has no move buttons" do
    [ @b, @c ].each(&:destroy)

    get plans_path

    assert_select "button.plan-move", count: 0
    assert_select ".plan-rank", count: 1
  end

  test "moving a plan up reorders the list and announces it" do
    patch move_plan_path(@b, direction: "up"), headers: STREAM

    assert_response :ok
    assert_equal [ @b, @a, @c ], order
    assert_includes response.body, "Moved #{@b.subject.name} up."
    assert_select "turbo-stream[action=update][target=plans-list]"
  end

  test "moving down works and the stream puts focus back on the button just used" do
    patch move_plan_path(@a, direction: "down"), headers: STREAM

    assert_equal [ @b, @a, @c ], order
    focused = Nokogiri::HTML.fragment(response.body).css("template").flat_map { |t| Nokogiri::HTML.fragment(t.inner_html).css("button[data-controller='focus-on-connect']") }
    assert_equal [ "Move #{@a.subject.name} down, priority 2 of 3" ], focused.map { |node| node["aria-label"] }
  end

  test "when a move leaves a plan at an end, focus goes to the other arrow because the one just used is now disabled" do
    patch move_plan_path(@b, direction: "down"), headers: STREAM

    assert_equal [ @a, @c, @b ], order
    focused = Nokogiri::HTML.fragment(response.body).css("template").flat_map { |t| Nokogiri::HTML.fragment(t.inner_html).css("button[data-controller='focus-on-connect']") }
    assert_equal [ "Move #{@b.subject.name} up, priority 3 of 3" ], focused.map { |node| node["aria-label"] }
    assert focused.none? { |node| node.key?("disabled") }
  end

  test "moving past an end says so and changes nothing" do
    patch move_plan_path(@a, direction: "up"), headers: STREAM

    assert_equal [ @a, @b, @c ], order
    assert_includes response.body, "#{@a.subject.name} is already first."
  end

  test "an unknown direction changes nothing" do
    patch move_plan_path(@b, direction: "sideways"), headers: STREAM

    assert_response :ok
    assert_equal [ @a, @b, @c ], order
  end

  test "without turbo it redirects back to the planner" do
    patch move_plan_path(@b, direction: "up")

    assert_redirected_to plans_path
    assert_equal [ @b, @a, @c ], order
  end

  test "someone else's plan is a 404 and nothing moves" do
    stranger = User.create!(email: "priority_stranger@example.com", password: "password123")
    foreign = Plan.create!(user: stranger, subject: @a.subject, plan_data: { "input" => {}, "output" => {} })

    patch move_plan_path(foreign, direction: "up"), headers: STREAM

    assert_response :not_found
    assert_equal [ @a, @b, @c ], order
  end

  test "guests can reorder their own plans" do
    sign_out @user
    get plans_path
    token = cookies[:guest_token]
    first = Plan.create!(guest_token: token, subject: Weapon.first, plan_data: { "input" => {}, "output" => {} })
    second = Plan.create!(guest_token: token, subject: Weapon.second, plan_data: { "input" => {}, "output" => {} })

    patch move_plan_path(second, direction: "up"), headers: STREAM

    assert_equal [ second, first ], Plan.where(guest_token: token).by_priority.to_a
  end

  test "creating a plan puts it last and the list shows its rank" do
    new_weapon = Weapon.where.not(id: [ @a, @b, @c ].map(&:subject_id)).first
    post plans_path, params: { plan: { subject_type: "Weapon", subject_id: new_weapon.id, current_level: 1, target_level: 20,
                                       current_ascension_rank: 0, target_ascension_rank: 1 } }, headers: STREAM

    assert_equal new_weapon.id, order.last.subject_id
    assert_equal 4, order.last.position
  end

  test "deleting a plan renumbers the list shown" do
    delete plan_path(@a), headers: STREAM

    assert_response :ok
    assert_includes response.body, "priority 1 of 2"
  end
end
