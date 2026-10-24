# How long it takes to regenerate a number of Waveplates.
#
# Game values (confirmed by the owner on 2026-10-24): one Waveplate regenerates
# every 6 minutes, and the Waveplate bar holds at most 240, which is also one
# day of regeneration. The optimizer's total is the Waveplates the plan still
# needs; `banked` is what the player already has, so only the rest has to
# regenerate. Returns minutes and whole days/hours for the views to format.
class WaveplateTimeline < ApplicationService
  REGEN_MINUTES = 6
  CAP = 240
  PER_DAY = 24 * 60 / REGEN_MINUTES

  def initialize(total:, banked: 0)
    @total = total.to_i
    @banked = banked.to_i.clamp(0, CAP)
  end

  def call
    needed = [ @total - @banked, 0 ].max
    minutes = needed * REGEN_MINUTES

    {
      total: @total,
      banked: @banked,
      needed: needed,
      minutes: minutes,
      days: minutes / (24 * 60),
      hours: minutes % (24 * 60) / 60,
      ready: needed.zero?,
      per_day: PER_DAY,
      cap: CAP
    }
  end
end
