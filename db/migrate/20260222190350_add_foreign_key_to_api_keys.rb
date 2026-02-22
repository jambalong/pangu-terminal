class AddForeignKeyToApiKeys < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :api_keys, :users
  end
end
