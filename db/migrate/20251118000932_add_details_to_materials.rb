class AddDetailsToMaterials < ActiveRecord::Migration[8.1]
  def change
    add_column :materials, :category, :string, null: false
    add_column :materials, :description, :text
  end
end
