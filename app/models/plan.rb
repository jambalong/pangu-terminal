class Plan < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :subject, polymorphic: true

  scope :planned_subject_ids, ->(type) {
    where(subject_type: type).pluck(:subject_id)
  }

  validate :must_have_owner

  def self.fetch_materials_summary(plans)
    totals = {}

    plans.each do |plan|
      materials = plan.plan_data.dig("output") || {}

      materials.each do |mat_id, quantity|
        totals[mat_id] ||= 0
        totals[mat_id] += quantity
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
