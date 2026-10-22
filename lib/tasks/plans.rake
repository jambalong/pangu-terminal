namespace :plans do
  desc "Recompute stored plans from their stored input. Dry run unless APPLY=1. Optional PLAN_ID or USER_ID."
  task recompute: :environment do
    scope = Plan.all
    scope = scope.where(id: ENV["PLAN_ID"]) if ENV["PLAN_ID"].present?
    scope = scope.where(user_id: ENV["USER_ID"]) if ENV["USER_ID"].present?
    apply = ENV["APPLY"] == "1"

    result = PlanRecomputer.call(scope: scope, apply: apply)

    names = Material.where(id: result[:changed].flat_map { |c| c[:diff].keys }).pluck(:id, :name).to_h
    result[:changed].each do |change|
      puts "Plan #{change[:plan_id]} (#{change[:subject]}):"
      change[:diff].each do |material_id, (old_qty, new_qty)|
        puts "  #{names[material_id] || material_id}: #{old_qty.inspect} -> #{new_qty.inspect}"
      end
    end
    result[:failed].each { |failure| puts "FAILED plan #{failure[:plan_id]}: #{failure[:error]}" }

    puts "#{apply ? 'Updated' : 'Would update'} #{result[:changed].size} plan(s); " \
         "#{result[:unchanged]} unchanged; #{result[:failed].size} failed."
    puts "Dry run only. Re-run with APPLY=1 to write." if !apply && result[:changed].any?
  end
end
