class WeaponMaterialMap < ApplicationRecord
  belongs_to :weapon
  belongs_to :material
end
