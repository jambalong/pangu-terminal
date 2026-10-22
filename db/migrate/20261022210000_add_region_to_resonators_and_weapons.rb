class AddRegionToResonatorsAndWeapons < ActiveRecord::Migration[8.1]
  # Which forgery/material set a Resonator or weapon uses ("base" or "lahai_roi";
  # same values as weapon_type_materials.region). Replaces name lists that lived
  # in the planners. Seeds set it; the default keeps unseeded rows on "base".
  def change
    add_column :resonators, :region, :string, null: false, default: "base"
    add_column :weapons, :region, :string, null: false, default: "base"
  end
end
