class CreateResonatorAscensionCosts < ActiveRecord::Migration[8.1]
  def change
    create_table :resonator_ascension_costs do |t|
      t.integer :ascension_rank, null: false
      t.string :material_type, null: false
      t.integer :rarity, default: 1, null: false
      t.integer :quantity, default: 0, null: false

      t.timestamps
    end
  end
end
