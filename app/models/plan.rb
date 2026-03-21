class Plan < ApplicationRecord
  EXP_POTION_TYPE_MAP = {
    "Resonator" => "resonator_exp",
    "Weapon" => "weapon_exp"
  }.freeze

  VALID_SUBJECT_TYPES = %w[Resonator Weapon].freeze

  belongs_to :user, optional: true
  belongs_to :subject, polymorphic: true, optional: true

  validates :subject_type, presence: true, inclusion: { in: VALID_SUBJECT_TYPES }
  validates :subject_id, presence: true
  validates :subject_id, uniqueness: { scope: [ :user_id, :subject_type ], message: "already has a plan" },
    if: -> { VALID_SUBJECT_TYPES.include?(subject_type) }
  validates :plan_data, presence: true
  validate :subject_must_exist, if: -> { VALID_SUBJECT_TYPES.include?(subject_type) && subject_id.present? }
  validate :must_have_owner

  scope :subject_ids_for_type, ->(type) { where(subject_type: type).pluck(:subject_id) }

  def self.fetch_materials_summary(plans)
    plans.each_with_object({}) do |plan, totals|
      plan.plan_data.dig("output").each do |material_id, qty|
        totals[material_id.to_i] = (totals[material_id.to_i] || 0) + qty
      end
    end
  end

  def owned_by?(user:, guest_token:)
    return user_id == user.id if user.present?
    self.guest_token == guest_token
  end

  private

  def must_have_owner
    if user_id.blank? && guest_token.blank?
      errors.add(:base, "Plan must belong to a user or a guest session")
    end
  end

  def subject_must_exist
    exists = subject_type.constantize.exists?(subject_id)
    errors.add(:subject, "must exist") unless exists
  end
end
