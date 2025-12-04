class RenameAttributeTypeToElementOnResonators < ActiveRecord::Migration[8.1]
  def change
    rename_column :resonators, :attribute_type, :element
  end
end
