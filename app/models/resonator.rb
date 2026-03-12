class Resonator < ApplicationRecord
  has_many :plans, as: :subject, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :element, presence: true
  validates :weapon_type, presence: true
end
