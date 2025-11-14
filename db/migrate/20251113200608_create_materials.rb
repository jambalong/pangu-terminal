class CreateMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :materials do |t|
      t.string :name, null: false
      t.integer :rarity, default: 1, null: false
      t.string :material_type, null: false
      t.integer :exp_value, default: 0, null: false

      t.timestamps
    end
  end
end
