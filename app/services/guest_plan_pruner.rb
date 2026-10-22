# Deletes plans that belong to a guest cookie nobody has touched for a while.
# Guests keep a permanent cookie, so abandoned guest plans otherwise accumulate
# forever. Dry run unless apply: true. Never touches plans owned by a user.
class GuestPlanPruner < ApplicationService
  DEFAULT_AGE = 90.days

  def initialize(older_than: DEFAULT_AGE, apply: false)
    @older_than = older_than
    @apply = apply
  end

  def call
    stale = Plan.where(user_id: nil).where("updated_at < ?", @older_than.ago)
    count = stale.count
    stale.delete_all if @apply && count.positive?

    { stale: count, deleted: @apply ? count : 0 }
  end
end
