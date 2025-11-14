class CreateWeaponMaterialMaps < ActiveRecord::Migration[8.1]
  def change
    create_table :weapon_material_maps do |t|
      t.references :weapon, null: false, foreign_key: true
      t.string :material_type, null: false
      t.integer :rarity, default: 1, null: false
      t.references :material, null: false, foreign_key: true

      t.timestamps
    end
  end
end
