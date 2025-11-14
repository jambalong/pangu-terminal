class CreateWeaponTypeMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :weapon_type_materials do |t|
      t.string :weapon_type, null: false
      t.string :material_type, null: false
      t.integer :rarity, default: 1, null: false
      t.references :material, null: false, foreign_key: true

      t.timestamps
    end
  end
end
