class ReviseDropRatesSchema < ActiveRecord::Migration[8.1]
  def change
    remove_index :drop_rates, [ :material_id, :source_id, :sol3_phase ]
    remove_reference :drop_rates, :material, foreign_key: true, index: true

    add_column :drop_rates, :rarity, :integer, null: false
    add_index :drop_rates, [ :source_id, :sol3_phase, :rarity ], unique: true
  end
end
