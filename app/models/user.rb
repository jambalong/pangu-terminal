class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :api_keys, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :inventory_items, dependent: :destroy
  has_many :materials, through: :inventory_items

  after_create :initialize_inventory

  private

  def initialize_inventory
    materials = Material.pluck(:id).map do |mat_id|
      {
        user_id: id,
        material_id: mat_id,
        quantity: 0,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    InventoryItem.insert_all(materials)
  end
end
