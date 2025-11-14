class CreateResonators < ActiveRecord::Migration[8.1]
  def change
    create_table :resonators do |t|
      t.string :name, null: false
      t.integer :rarity, default: 4, null: false
      t.string :attribute_type, null: false
      t.string :weapon_type, null: false

      t.timestamps
    end
  end
end
