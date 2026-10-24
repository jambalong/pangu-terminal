require "test_helper"

class WaveplateTimelineTest < ActiveSupport::TestCase
  def timeline(total, banked = 0) = WaveplateTimeline.call(total: total, banked: banked)

  test "uses one Waveplate per six minutes, a cap of 240 and 240 a day" do
    assert_equal 6, WaveplateTimeline::REGEN_MINUTES
    assert_equal 240, WaveplateTimeline::CAP
    assert_equal 240, WaveplateTimeline::PER_DAY
  end

  test "a day's worth of Waveplates takes exactly one day" do
    result = timeline(240)

    assert_equal 1440, result[:minutes]
    assert_equal [ 1, 0 ], [ result[:days], result[:hours] ]
  end

  test "splits a longer wait into whole days and hours" do
    result = timeline(2300)

    assert_equal 13_800, result[:minutes]
    assert_equal [ 9, 14 ], [ result[:days], result[:hours] ]
  end

  test "a small total is hours or minutes" do
    assert_equal 600, timeline(100)[:minutes]
    assert_equal [ 0, 10 ], [ timeline(100)[:days], timeline(100)[:hours] ]
    assert_equal 30, timeline(5)[:minutes]
  end

  test "Waveplates already banked reduce the wait" do
    result = timeline(300, 60)

    assert_equal 240, result[:needed]
    assert_equal 1440, result[:minutes]
  end

  test "a bank that covers the total means ready now" do
    assert timeline(100, 150)[:ready]
    assert_equal 0, timeline(100, 150)[:minutes]
    assert timeline(0)[:ready]
  end

  test "the bank is limited to the cap and never negative" do
    assert_equal 240, timeline(1000, 5000)[:banked]
    assert_equal 0, timeline(1000, -5)[:banked]
    assert_equal 760, timeline(1000, 5000)[:needed]
  end

  test "nil and string inputs do not raise" do
    assert_equal 0, WaveplateTimeline.call(total: nil, banked: nil)[:minutes]
    assert_equal 60, WaveplateTimeline.call(total: "10", banked: "0")[:minutes]
  end
end
