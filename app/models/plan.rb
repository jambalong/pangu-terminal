class Plan < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :subject, polymorphic: true

  validates :subject_type, presence: true, inclusion: { in: %w[Resonator Weapon] }
  validates :subject_id, presence: true
  validates :plan_data, presence: true
  validate :must_have_owner

  scope :subject_ids_for_type, ->(type) { where(subject_type: type).pluck(:subject_id) }

  def self.fetch_materials_summary(plans)
    totals = {}

    plans.each do |plan|
      materials = plan.plan_data.dig("output") || {}

      materials.each do |material_id, quantity|
        key = material_id.to_i
        totals[key] ||= 0
        totals[key] += quantity
      end
    end

    totals
  end

  private

  def must_have_owner
    if user_id.blank? && guest_token.blank?
      errors.add(:base, "Plan must belong to a user or a guest session")
    end
  end
end
