class AddShareTokenToPlans < ActiveRecord::Migration[8.1]
  # A random token that makes a plan viewable (read-only) at /p/<token>.
  # NULL means not shared. Additive and reversible.
  def change
    add_column :plans, :share_token, :string
    add_index :plans, :share_token, unique: true
  end
end
