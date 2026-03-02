class Material < ApplicationRecord
  CATEGORY_ORDER = [
    "Universal Currency",
    "Resonator EXP Material",
    "Weapon EXP Material",
    "Resonator Ascension Material",
    "Ascension Material",
    "Weapon and Skill Material",
    "Skill Upgrade Material"
  ].freeze

  MATERIAL_TYPE_ORDER = [
    "Credit",
    "ResonatorEXP",
    "WeaponEXP",
    "BossDrop",
    "Flower",
    "EnemyDrop",
    "ForgeryDrop",
    "WeeklyBossDrop"
  ].freeze

  validates :name, presence: true, uniqueness: true
  validates :material_type, presence: true
  validates :category, presence: true
  validates :rarity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :exp_value, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :index_by_ids, ->(ids) { where(id: ids).index_by(&:id) }
  scope :ordered_categories, -> {
    distinct.pluck(:category).sort_by { |category| CATEGORY_ORDER.index(category) || CATEGORY_ORDER.length }
  }

  def snake_case_name
    name.downcase.gsub(/['"#&]/, "").strip.gsub(/[-\s]+/, "_")
  end
end
