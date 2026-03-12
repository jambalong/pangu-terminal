class AddUniqueIndexToResonatorAndWeaponNames < ActiveRecord::Migration[8.1]
  def change
    add_index :resonators, :name, unique: true
    add_index :weapons, :name, unique: true
  end
end
