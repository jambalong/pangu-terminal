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
  # Guests have a nil user_id, so scoping on it alone would make every guest
  # collide with every other guest. Scope guests by their token instead.
  validates :subject_id, uniqueness: { scope: [ :user_id, :subject_type ], message: "already has a plan" },
    if: -> { user_id.present? && VALID_SUBJECT_TYPES.include?(subject_type) }
  validates :subject_id, uniqueness: { scope: [ :guest_token, :subject_type ], message: "already has a plan" },
    if: -> { user_id.blank? && VALID_SUBJECT_TYPES.include?(subject_type) }
  validates :plan_data, presence: true
  validate :subject_must_exist, if: -> { VALID_SUBJECT_TYPES.include?(subject_type) && subject_id.present? }
  validate :must_have_owner

  # Priority order: explicit positions first-to-last, with plans that have none
  # (created before priorities existed) ahead of them in creation order.
  scope :by_priority, -> { order(Arel.sql("COALESCE(plans.position, 0) ASC, plans.created_at ASC, plans.id ASC")) }

  before_create :assign_position

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

  # Sharing: a random 128-bit token makes the plan's materials viewable at
  # /p/<token> without an account. Revoking deletes the token, which kills the link.
  def shared?
    share_token.present?
  end

  def share!
    update_columns(share_token: SecureRandom.urlsafe_base64(16)) unless shared?
    share_token
  end

  def unshare!
    update_columns(share_token: nil)
  end

  private

  # New plans go to the end of their owner's list (a user's, or a guest's).
  def assign_position
    return if position

    siblings = user_id ? Plan.where(user_id: user_id) : Plan.where(user_id: nil, guest_token: guest_token)
    self.position = (siblings.maximum(:position) || 0) + 1
  end

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
