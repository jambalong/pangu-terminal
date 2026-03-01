class AddLastUsedAtToApiKeys < ActiveRecord::Migration[8.1]
  def change
    add_column :api_keys, :last_used_at, :datetime
  end
end
