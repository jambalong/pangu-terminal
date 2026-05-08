class AddForteIconsToResonators < ActiveRecord::Migration[8.1]
  def change
    add_column :resonators, :forte_icons, :jsonb, default: {}
  end
end
