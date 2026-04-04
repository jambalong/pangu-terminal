class CreateDropRates < ActiveRecord::Migration[8.1]
  def change
    create_table :drop_rates do |t|
      t.references :material, null: false, foreign_key: true
      t.references :source, null: false, foreign_key: true
      t.integer :sol3_phase, null: false
      t.decimal :avg_quantity, null: false, precision: 8, scale: 3

      t.timestamps
    end

    add_index :drop_rates, [ :material_id, :source_id, :sol3_phase ], unique: true
  end
end
