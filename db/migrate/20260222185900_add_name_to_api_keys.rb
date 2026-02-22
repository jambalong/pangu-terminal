class AddNameToApiKeys < ActiveRecord::Migration[8.1]
  def change
    add_column :api_keys, :name, :string, null: false
  end
end
