class AddItemGroupIdToMaterials < ActiveRecord::Migration[8.1]
  def change
    add_column :materials, :item_group_id, :string
    add_index :materials, :item_group_id
  end
end
