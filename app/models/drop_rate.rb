class DropRate < ApplicationRecord
  belongs_to :material
  belongs_to :source

  validates :sol3_phase, presence: true, numericality: { only_integer: true, in: 1..8 }
  validates :avg_quantity, presence: true, numericality: { greater_than: 0 }
  validates :material_id, uniqueness: { scope: [ :source_id, :sol3_phase ] }
end
