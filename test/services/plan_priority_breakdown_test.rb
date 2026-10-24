require "test_helper"

class PlanPriorityBreakdownTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "breakdown@example.com", password: "password123", sol3_phase: 3)
    @shell = Material.find_by!(name: "Shell Credit")
    @core = Material.find_by!(name: "Basic Energy Core")
    @plans = Weapon.limit(3).each_with_index.map do |weapon, index|
      Plan.create!(user: @user, subject: weapon,
                   plan_data: { "input" => {}, "output" => { @shell.id.to_s => 1000 * (index + 1), @core.id.to_s => 10 * (index + 1) } })
    end
  end

  def breakdown(plans = @plans, banked: 0) = PlanPriorityBreakdown.call(user: @user, plans: plans, banked: banked)

  test "needs at least two plans" do
    assert_equal [], breakdown([])
    assert_equal [], breakdown(@plans.first(1))
  end

  test "gives one step per plan in the given order with ranks" do
    steps = breakdown

    assert_equal @plans, steps.map { |step| step[:plan] }
    assert_equal [ 1, 2, 3 ], steps.map { |step| step[:rank] }
  end

  test "the steps add up to what the optimizer says for all of them" do
    steps = breakdown
    total = OptimizerService.call(user: @user, plans: @plans)[:totals][:total_wp]

    assert_equal total, steps.last[:cumulative]
    assert_equal total, steps.sum { |step| step[:waveplates] }
  end

  test "running totals never go down and each step is its own difference" do
    steps = breakdown

    assert_equal steps.map { |step| step[:cumulative] }.sort, steps.map { |step| step[:cumulative] }
    steps.each_cons(2) { |before, after| assert_equal after[:cumulative] - before[:cumulative], after[:waveplates] }
    assert_equal steps.first[:cumulative], steps.first[:waveplates]
  end

  test "the order matters for the step sizes but not the grand total" do
    forward = breakdown(@plans)
    backward = breakdown(@plans.reverse)

    assert_equal forward.last[:cumulative], backward.last[:cumulative]
    assert_equal @plans.reverse, backward.map { |step| step[:plan] }
  end

  test "each step carries the regeneration time for the running total, minus the bank" do
    steps = breakdown(banked: 20)

    steps.each do |step|
      assert_equal WaveplateTimeline.call(total: step[:cumulative], banked: 20), step[:timeline]
    end
  end

  test "too many plans are skipped rather than run dozens of optimizers" do
    many = Array.new(PlanPriorityBreakdown::MAX_PLANS + 1) { @plans.first }

    assert_equal [], breakdown(many)
  end

  test "stays within a bounded number of queries for a handful of plans" do
    count = 0
    counter = ->(*, payload) { count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name]) || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { breakdown }

    assert_operator count, :<=, 60
  end
end
