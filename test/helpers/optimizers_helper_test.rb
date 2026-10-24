require "test_helper"

class OptimizersHelperTest < ActionView::TestCase
  test "returns base class when sources are present" do
    data = { sources: [ "Moonlit Groves" ] }
    attrs = material_card_attrs(data)

    assert_equal "optimizer-material-card", attrs[:class]
    assert_nil attrs[:data]
  end

  test "adds hidden class and toggle target when sources are empty" do
    data = { sources: [] }
    attrs = material_card_attrs(data)

    assert_includes attrs[:class], "hidden"
    assert_equal({ toggle_target: "item" }, attrs[:data])
  end

  test "waveplate_duration reads as plain words" do
    assert_equal "Ready now", waveplate_duration(0)
    assert_equal "Ready now", waveplate_duration(-5)
    assert_equal "30 min", waveplate_duration(30)
    assert_equal "1 h", waveplate_duration(60)
    assert_equal "7 h 30 min", waveplate_duration(450)
    assert_equal "1 day", waveplate_duration(1440)
    assert_equal "9 days 14 h", waveplate_duration(13_800)
  end

  test "waveplate_duration drops minutes once there are days" do
    assert_equal "2 days 1 h", waveplate_duration(2 * 1440 + 65)
  end
end
