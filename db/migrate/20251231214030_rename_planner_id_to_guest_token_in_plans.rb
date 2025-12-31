class RenamePlannerIdToGuestTokenInPlans < ActiveRecord::Migration[8.1]
  def change
    rename_column :plans, :planner_id, :guest_token
  end
end
