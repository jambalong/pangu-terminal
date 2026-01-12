class AddPolymorphicSubjectToPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :plans, :subject_type, :string, null: false
    remove_index :plans, [ :subject_id, :plan_type ]
    add_index :plans, [ :subject_id, :subject_type ]
    remove_column :plans, :plan_type, :string
  end
end
