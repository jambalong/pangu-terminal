class DropRate < ApplicationRecord
  belongs_to :source

  validates :sol3_phase, presence: true, numericality: { only_integer: true, in: 1..8 }
  validates :rarity, presence: true, numericality: { only_integer: true, in: 1..5 }
  validates :avg_quantity, presence: true, numericality: { greater_than: 0 }
  validates :source_id, uniqueness: { scope: [ :sol3_phase, :rarity, :material_type ] }
end
