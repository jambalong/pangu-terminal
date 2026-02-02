class InventoryItem < ApplicationRecord
  belongs_to :user
  belongs_to :material

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :material_id, message: "can only have one inventory item per material" }

  # Allows inventory_item.name instead of material.name
  delegate :name, :rarity, :material_type, :category, to: :material

  scope :search_by_name, ->(query) { joins(:material).where("materials.name ILIKE ?", "%#{query}%") }
  scope :by_category, ->(category) { joins(:material).where(materials: { category: category }) }
end
