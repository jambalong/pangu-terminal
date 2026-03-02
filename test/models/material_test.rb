# test/models/material_test.rb
require "test_helper"

class MaterialTest < ActiveSupport::TestCase
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
end
