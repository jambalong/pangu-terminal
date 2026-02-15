class AddImageUrlToResonators < ActiveRecord::Migration[8.1]
  def change
    add_column :resonators, :image_url, :string, null: true
  end
end
