require "test_helper"
require "rake"

class PlansRakeTest < ActiveSupport::TestCase
  setup do
    # Load only this file: loading every rake file would pull untested download
    # tasks into the coverage report.
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    load Rails.root.join("lib/tasks/plans.rake") unless Rake::Task.task_defined?("plans:recompute")
    @task = Rake::Task["plans:recompute"]
    @task.reenable

    user = User.create!(email: "rake@example.com", password: "password123")
    @shell_credit = Material.find_by!(name: "Shell Credit")
    @plan = PlanForm.new(
      subject_type: "Weapon", subject_id: Weapon.find_by!(name: "Kumokiri").id,
      current_level: 1, target_level: 20, current_ascension_rank: 0, target_ascension_rank: 1
    ).save(user, nil)
    @correct = @plan.plan_data["output"][@shell_credit.id.to_s]
    stale = @plan.plan_data.deep_dup
    stale["output"][@shell_credit.id.to_s] = 1
    @plan.update_columns(plan_data: stale)
  end

  teardown do
    ENV.delete("APPLY")
    ENV.delete("PLAN_ID")
  end

  test "dry run prints the diff and writes nothing" do
    ENV["PLAN_ID"] = @plan.id.to_s

    out, = capture_io { @task.invoke }

    assert_includes out, "Shell Credit: 1 -> #{@correct}"
    assert_includes out, "Would update 1 plan(s)"
    assert_includes out, "APPLY=1"
    assert_equal 1, @plan.reload.plan_data["output"][@shell_credit.id.to_s]
  end

  test "APPLY=1 writes the corrected output" do
    ENV["PLAN_ID"] = @plan.id.to_s
    ENV["APPLY"] = "1"

    out, = capture_io { @task.invoke }

    assert_includes out, "Updated 1 plan(s)"
    assert_equal @correct, @plan.reload.plan_data["output"][@shell_credit.id.to_s]
  end

  test "prune_guests dry run reports and APPLY=1 deletes" do
    @task.reenable
    Rake::Task["plans:prune_guests"].reenable
    guest = Plan.create!(guest_token: "old-guest", subject: Weapon.find_by!(name: "Kumokiri"), plan_data: { "input" => {}, "output" => {} })
    guest.update_columns(updated_at: 200.days.ago)

    out, = capture_io { Rake::Task["plans:prune_guests"].invoke }
    assert_includes out, "Would delete 1 guest plan(s)"
    assert Plan.exists?(guest.id)

    Rake::Task["plans:prune_guests"].reenable
    ENV["APPLY"] = "1"
    out, = capture_io { Rake::Task["plans:prune_guests"].invoke }
    assert_includes out, "Deleted 1 guest plan(s)"
    assert_not Plan.exists?(guest.id)
  end
end
