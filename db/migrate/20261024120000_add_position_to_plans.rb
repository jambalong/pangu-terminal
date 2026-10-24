class AddPositionToPlans < ActiveRecord::Migration[8.1]
  # Plan priority: 1 is farmed first. Nullable so existing plans need no
  # backfill; they sort first, in creation order, until the owner reorders.
  def change
    add_column :plans, :position, :integer
    add_index :plans, [ :user_id, :position ]
  end
end
