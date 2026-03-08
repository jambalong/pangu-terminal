class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :source_type, null: false
      t.integer :waveplate_cost, null: false
      t.string :location, null: false
      t.string :region, null: false

      t.timestamps
    end

    add_index :sources, :name, unique: true
    add_index :sources, :source_type
    add_index :sources, :region
  end
end
