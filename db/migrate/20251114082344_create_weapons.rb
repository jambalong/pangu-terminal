class CreateWeapons < ActiveRecord::Migration[8.1]
  def change
    create_table :weapons do |t|
      t.string :name, null: false
      t.string :weapon_type, null: false
      t.integer :rarity, default: 1, null: false

      t.timestamps
    end
  end
end
