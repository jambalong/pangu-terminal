class Plan < ApplicationRecord
  belongs_to :user, optional: true

  validate :must_have_owner

  private

  def must_have_owner
    if user_id.blank? && guest_token.blank?
      errors.add(:base, "Plan must belong to a user or a guest session")
    end
  end
end
