class AddRegionToWeaponTypeMaterial < ActiveRecord::Migration[8.1]
  def change
    add_column :weapon_type_materials, :region, :string
  end
end
