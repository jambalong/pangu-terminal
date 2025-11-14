class CreateResonatorMaterialMaps < ActiveRecord::Migration[8.1]
  def change
    create_table :resonator_material_maps do |t|
      t.references :resonator, null: false, foreign_key: true
      t.string :material_type, null: false
      t.integer :rarity, default: 1, null: false
      t.references :material, null: false, foreign_key: true

      t.timestamps
    end
  end
end
