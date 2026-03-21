require "test_helper"

class MaterialTest < ActiveSupport::TestCase
  setup do
    @material = Material.find_by!(name: "Cadence Seed")
  end

  test "valid material" do
    assert @material.valid?
  end

  test "invalid without name" do
    material = build_material(name: nil)
    assert material.invalid?
    assert material.errors[:name].any?
  end

  test "invalid with duplicate name" do
    material = build_material(name: @material.name)
    assert material.invalid?
    assert material.errors[:name].any?
  end

  test "invalid without material_type" do
    material = build_material(material_type: nil)
    assert material.invalid?
    assert material.errors[:material_type].any?
  end

  test "invalid without category" do
    material = build_material(category: nil)
    assert material.invalid?
    assert material.errors[:category].any?
  end

  test "invalid without rarity" do
    material = build_material(rarity: nil)
    assert material.invalid?
    assert material.errors[:rarity].any?
  end

  test "invalid with rarity 0" do
    material = build_material(rarity: 0)
    assert material.invalid?
    assert material.errors[:rarity].any?
  end

  test "invalid with rarity 6" do
    material = build_material(rarity: 6)
    assert material.invalid?
    assert material.errors[:rarity].any?
  end

  test "valid with rarity 1" do
    material = build_material(rarity: 1)
    assert material.valid?
  end

  test "valid with rarity 5" do
    material = build_material(rarity: 5)
    assert material.valid?
  end

  test "invalid without exp_value" do
    material = build_material(exp_value: nil)
    assert material.invalid?
    assert material.errors[:exp_value].any?
  end

  test "invalid with negative exp_value" do
    material = build_material(exp_value: -1)
    assert material.invalid?
    assert material.errors[:exp_value].any?
  end

  test "valid with exp_value 0" do
    material = build_material(exp_value: 0)
    assert material.valid?
  end

  test "snake_case_name downcases material name" do
    material = Material.new(name: "Cadence Seed")
    assert_equal "cadence_seed", material.snake_case_name
  end

  test "snake_case_name replaces spaces with underscores" do
    material = Material.new(name: "Cadence Bud")
    assert_equal "cadence_bud", material.snake_case_name
  end

  test "snake_case_name strips special characters" do
    material = Material.new(name: "The Netherworld's Stare")
    assert_equal "the_netherworlds_stare", material.snake_case_name
  end

  test "snake_case_name replaces hyphens with underscores" do
    material = Material.new(name: "Golden-Dissolving Feather")
    assert_equal "golden_dissolving_feather", material.snake_case_name
  end

  test "snake_case_name handles multiple spaces" do
    material = Material.new(name: "Cadence  Seed")
    assert_equal "cadence_seed", material.snake_case_name
  end

  test "snake_case_name strips leading and trailing whitespace" do
    material = Material.new(name: "  Cadence Seed  ")
    assert_equal "cadence_seed", material.snake_case_name
  end

  private

  def build_material(overrides = {})
    Material.new(
      name: "Test Material",
      material_type: @material.material_type,
      category: @material.category,
      rarity: 3,
      exp_value: 0,
      **overrides
    )
  end
end
