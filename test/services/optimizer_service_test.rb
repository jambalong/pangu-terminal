require "test_helper"

class OptimizerServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "optimizer_service@example.com", password: "password123", sol3_phase: 3)
    @shell_credit = Material.find_by!(name: "Shell Credit")
    @basic_energy_core = Material.find_by!(name: "Basic Energy Core")
    @lf_whisperin_core = Material.find_by!(name: "LF Whisperin Core")

    @plan = Plan.create!(
      user: @user,
      subject: Weapon.find_by!(name: "Kumokiri"),
      plan_data: {
        "input" => {},
        "output" => {
          @shell_credit.id.to_s => 25480,
          @basic_energy_core.id.to_s => 38,
          @lf_whisperin_core.id.to_s => 6
        }
      }
    )
  end

  test "returns results, chain coverage and totals for deficit materials" do
    result = OptimizerService.call(user: @user, plan: @plan)

    assert_equal [ @shell_credit.id, @basic_energy_core.id, @lf_whisperin_core.id ].sort, result[:results].keys.sort
    assert_equal 25480, result[:results][@shell_credit.id][:deficit]
    assert_kind_of Hash, result[:chain_coverage]
    assert_operator result[:totals][:total_runs], :>, 0
    assert_operator result[:totals][:total_wp], :>, 0
  end

  test "excludes materials the inventory already covers" do
    @user.inventory_item_for(@shell_credit).update!(quantity: 25480)

    result = OptimizerService.call(user: @user, plan: @plan)

    assert_not_includes result[:results].keys, @shell_credit.id
  end

  test "returns empty results for a plan without output" do
    @plan.update!(plan_data: { "input" => {}, "output" => {} })

    result = OptimizerService.call(user: @user, plan: @plan)

    assert_empty result[:results]
    assert_equal({ total_runs: 0, total_wp: 0 }, result[:totals])
  end

  test "stays within a bounded number of queries" do
    count = 0
    counter = ->(*, payload) { count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name]) || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      OptimizerService.call(user: @user, plan: @plan)
    end
    # Measured at 11 for these three materials; a jump means a new N+1.
    assert_operator count, :<=, 15
  end
end
