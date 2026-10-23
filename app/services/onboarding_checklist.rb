# What a new account still has to do before the app is useful, worked out from
# the user's own data (no stored flags): SOL3 phase set, a plan created, and
# some inventory entered. The dashboard shows the checklist until all are done.
class OnboardingChecklist < ApplicationService
  def initialize(user:)
    @user = user
  end

  def call
    steps = [
      { key: :sol3_phase, done: @user.sol3_phase.present? },
      { key: :plan, done: @user.plans.exists? },
      { key: :inventory, done: owns_anything? }
    ]

    { steps: steps, complete: steps.all? { |step| step[:done] } }
  end

  private

  def owns_anything?
    @user.inventory_items.where("quantity > 0").exists?
  end
end
