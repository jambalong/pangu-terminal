class UpdateForteNodeCostIdentifier < ActiveRecord::Migration[8.1]
  def change
    change_table :forte_node_costs do |t|
      t.remove :node_type
      t.remove :node_tier
      t.string :node_identifier, null: false

      add_index :forte_node_costs,
                [ :node_identifier, :material_type, :rarity ],
                unique: true
    end
  end
end
