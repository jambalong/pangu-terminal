class CreateResonatorLevelCosts < ActiveRecord::Migration[8.1]
  def change
    create_table :resonator_level_costs do |t|
      t.integer :level, null: false
      t.integer :exp_required, default: 0, null: false
      t.integer :credit_cost, default: 0, null: false

      t.timestamps
    end
  end
end
