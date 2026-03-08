class Source < ApplicationRecord
  has_many :material_sources
  has_many :materials, through: :material_sources

  validates :name, presence: true, uniqueness: true
  validates :source_type, presence: true
  validates :waveplate_cost, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :location, presence: true
  validates :region, presence: true
end
