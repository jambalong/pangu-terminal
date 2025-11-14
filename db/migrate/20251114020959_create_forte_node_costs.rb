class CreateForteNodeCosts < ActiveRecord::Migration[8.1]
  def change
    create_table :forte_node_costs do |t|
      t.string :node_type, null: false
      t.integer :node_tier, null: false
      t.string :material_type, null: false
      t.integer :rarity, default: 1, null: false
      t.integer :quantity, default: 0, null: false

      t.timestamps
    end
  end
end
