class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.integer :user_id, null: false
      t.string :token, null: false
      t.timestamps
    end

    add_index :api_keys, :user_id
    add_index :api_keys, :token, unique: true
  end
end
