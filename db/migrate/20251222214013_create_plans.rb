class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string :planner_id, null: false
      t.string :plan_type, null: false
      t.jsonb :plan_data, null: false, default: {}

      t.timestamps
    end

    add_index :plans, :planner_id
  end
end
