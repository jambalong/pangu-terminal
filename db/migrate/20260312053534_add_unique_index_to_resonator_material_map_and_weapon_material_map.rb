class AddUniqueIndexToResonatorMaterialMapAndWeaponMaterialMap < ActiveRecord::Migration[8.1]
  def change
    add_index :resonator_material_maps, [ :material_id, :material_type, :resonator_id  ], unique: true
    add_index :weapon_material_maps, [ :material_id, :material_type, :weapon_id  ], unique: true
  end
end
