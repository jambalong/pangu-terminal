require "test_helper"

class DropRateServiceTest < ActiveSupport::TestCase
  def setup
    @source = Source.find_by!(name: "Moonlit Groves")
    @material = Material.find_by!(name: "Cadence Bud")
    @sol3_phase = 5
    @deficit = 10
  end

  test "returns estimated runs and waveplate cost for a single source material" do
    results = DropRateService.call(@material, @deficit, @sol3_phase)

    assert results.key?("Moonlit Groves")
    assert_equal 3, results["Moonlit Groves"][:estimated_runs]
    assert_equal 120, results["Moonlit Groves"][:waveplate_cost]
  end

  test "returns one entry per source for a material with multiple sources" do
    results = DropRateService.call(@material, @deficit, @sol3_phase)

    assert results.key?("Moonlit Groves")
    assert results.key?("Abyss of Sacrifice")
  end

  test "returns empty hash when deficit is zero" do
    results = DropRateService.call(@material, 0, @sol3_phase)

    assert_empty results
  end

  test "skips source and returns empty hash when no drop rate row exists" do
    results = DropRateService.call(@material, @deficit, 1)

    assert_empty results
  end

  test "raises ArgumentError when material is nil" do
    assert_raises(ArgumentError) { DropRateService.call(nil, @deficit, @sol3_phase) }
  end

  test "raises ArgumentError when deficit is nil" do
    assert_raises(ArgumentError) { DropRateService.call(@material, nil, @sol3_phase) }
  end

  test "raises ArgumentError when sol3_phase is nil" do
    assert_raises(ArgumentError) { DropRateService.call(@material, @deficit, nil) }
  end

  test "raises ArgumentError when material is not a Material" do
    assert_raises(ArgumentError) { DropRateService.call("cadence_bud", @deficit, @sol3_phase) }
  end

  test "raises ArgumentError when deficit is not an integer" do
    assert_raises(ArgumentError) { DropRateService.call(@material, "10", @sol3_phase) }
  end

  test "raises ArgumentError when sol3_phase is not an integer" do
    assert_raises(ArgumentError) { DropRateService.call(@material, @deficit, "5") }
  end
end
