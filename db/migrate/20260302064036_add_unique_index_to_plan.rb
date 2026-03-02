class AddUniqueIndexToPlan < ActiveRecord::Migration[8.1]
  def change
    add_index :plans, [ :user_id, :subject_type, :subject_id ], unique: true
  end
end
