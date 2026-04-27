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
end
