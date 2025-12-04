class CreateWeaponAscensionCosts < ActiveRecord::Migration[8.1]
  def change
    create_table :weapon_ascension_costs do |t|
      t.integer :weapon_rarity, default: 4, null: false
      t.integer :ascension_rank, null: false
      t.string :material_type, null: false
      t.integer :rarity, default: 1, null: false
      t.integer :quantity, default: 0, null: false

      t.timestamps
    end
  end
end
