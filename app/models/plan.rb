class Plan < ApplicationRecord
  EXP_POTION_TYPE_MAP = {
    "Resonator" => "ResonatorEXP",
    "Weapon" => "WeaponEXP"
  }.freeze

  belongs_to :user, optional: true
  belongs_to :subject, polymorphic: true

  validates :subject_type, presence: true, inclusion: { in: %w[Resonator Weapon] }
  validates :subject_id, presence: true
  validates :plan_data, presence: true
  validate :must_have_owner

  scope :subject_ids_for_type, ->(type) { where(subject_type: type).pluck(:subject_id) }

  def self.fetch_materials_summary(plans)
    plans.each_with_object({}) do |plan, totals|
      plan.plan_data.dig("output").each do |material_id, qty|
        totals[material_id.to_i] = (totals[material_id.to_i] || 0) + qty
      end
    end
  end

  private

  def must_have_owner
    if user_id.blank? && guest_token.blank?
      errors.add(:base, "Plan must belong to a user or a guest session")
    end
  end
end
