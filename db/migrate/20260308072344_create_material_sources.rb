class CreateMaterialSources < ActiveRecord::Migration[8.1]
  def change
    create_table :material_sources do |t|
      t.references :material, null: false, foreign_key: true
      t.references :source, null: false, foreign_key: true

      t.timestamps
    end

    add_index :material_sources, [ :material_id, :source_id ], unique: true
  end
end
