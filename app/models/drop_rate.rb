class DropRate < ApplicationRecord
  # SOL3 phases the game (and therefore the app) knows about. Used by drop rate
  # validation, the user's profile validation, the dashboard dropdown and the API.
  SOL3_PHASES = (1..8).freeze

  belongs_to :source

  validates :sol3_phase, presence: true, numericality: { only_integer: true, in: SOL3_PHASES }
  validates :rarity, presence: true, numericality: { only_integer: true, in: 1..5 }
  validates :avg_quantity, presence: true, numericality: { greater_than: 0 }
  validates :source_id, uniqueness: { scope: [ :sol3_phase, :rarity, :material_type ] }
end
