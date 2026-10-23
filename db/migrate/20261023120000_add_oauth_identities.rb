class AddOauthIdentities < ActiveRecord::Migration[8.1]
  def up
    create_table :identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.timestamps
    end
    add_index :identities, [ :provider, :uid ], unique: true
    add_index :identities, [ :user_id, :provider ], unique: true

    add_column :users, :display_name, :string

    # OAuth accounts have no email. The unique index on email stays: Postgres
    # treats NULLs as distinct, so any number of accounts may have no email.
    change_column_default :users, :email, from: "", to: nil
    change_column_null :users, :email, true
    execute "UPDATE users SET email = NULL WHERE email = ''"
  end

  def down
    execute "UPDATE users SET email = 'user-' || id || '@invalid.example' WHERE email IS NULL"
    change_column_null :users, :email, false
    change_column_default :users, :email, from: nil, to: ""
    remove_column :users, :display_name
    drop_table :identities
  end
end
