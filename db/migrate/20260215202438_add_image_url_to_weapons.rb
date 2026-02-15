class AddImageUrlToWeapons < ActiveRecord::Migration[8.1]
  def change
    add_column :weapons, :image_url, :string, null: true
  end
end
