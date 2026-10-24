require "test_helper"

class QuantityParserTest < ActiveSupport::TestCase
  def parse(raw, **options) = QuantityParser.parse(raw, **options)

  test "whole numbers, thousands separators and trailing .0 are accepted" do
    assert_equal 1200, parse("1200")
    assert_equal 1200, parse("1,200")
    assert_equal 1200, parse("1 200")
    assert_equal 1200, parse("1_200")
    assert_equal 5, parse("5.0")
    assert_equal 5, parse(" 5 ")
    assert_equal 0, parse("0")
  end

  test "integers and integral floats from JSON are accepted" do
    assert_equal 7, parse(7)
    assert_equal 7, parse(7.0)
    assert_nil parse(7.5)
    assert_nil parse(-1)
    assert_nil parse(-1.0)
  end

  test "anything else is not a quantity" do
    [ "", "abc", "-5", "1.5", "12abc", "1e3", "0x10", nil, [], {} ].each do |raw|
      assert_nil parse(raw), "#{raw.inspect} should not parse"
    end
  end

  test "suffixes are off by default" do
    assert_nil parse("25k")
    assert_nil parse("2m")
  end

  test "k and m suffixes work when typing" do
    assert_equal 25_000, parse("25k", suffixes: true)
    assert_equal 25_000, parse("25K", suffixes: true)
    assert_equal 1500, parse("1.5k", suffixes: true)
    assert_equal 2_000_000, parse("2m", suffixes: true)
    assert_equal 1_250_000, parse("1.25m", suffixes: true)
    assert_equal 120, parse("120", suffixes: true)
  end

  test "suffixes that do not give a whole number are rejected" do
    assert_nil parse("1.2345k", suffixes: true)
    assert_nil parse("k", suffixes: true)
    assert_nil parse("5kk", suffixes: true)
    assert_nil parse("-5k", suffixes: true)
  end
end
