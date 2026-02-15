class AddImageUrlToMaterials < ActiveRecord::Migration[8.1]
  def change
    add_column :materials, :image_url, :string, null: true
  end
end
