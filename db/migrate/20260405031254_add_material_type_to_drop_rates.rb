class AddMaterialTypeToDropRates < ActiveRecord::Migration[8.1]
  def change
    add_column :drop_rates, :material_type, :string, null: false

    remove_index :drop_rates, [ :source_id, :sol3_phase, :rarity ]
    add_index :drop_rates, [ :source_id, :sol3_phase, :rarity, :material_type ], unique: true, name: "index_drop_rates_uniqueness"
  end
end
