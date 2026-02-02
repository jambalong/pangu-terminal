require "test_helper"

class SynthesisServiceTest < ActiveSupport::TestCase
  setup do
    @forgery_material = Material.create!(
      name: "Cadence Seed",
      material_type: "ForgeryDrop",
      category: "Weapon and Skill Material",
      rarity: 2,
      exp_value: 0
    )
  end

  test "reconcile_inventory calculates deficit correctly" do
    inventory = { @forgery_material.id => 60 }
    requirements = { @forgery_material.id => 100 }

    result = SynthesisService.new(inventory, requirements).reconcile_inventory

    assert_equal 100, result[@forgery_material.id][:needed]
    assert_equal 60, result[@forgery_material.id][:owned]
    assert_equal 40, result[@forgery_material.id][:deficit]
    assert_equal false, result[@forgery_material.id][:satisfied]
  end

  test "reconcile_inventory returns satisfied when owned >= needed" do
    inventory = { @forgery_material.id => 100 }
    requirements = { @forgery_material.id => 100 }

    result = SynthesisService.new(inventory, requirements).reconcile_inventory

    assert_equal 0, result[@forgery_material.id][:deficit]
    assert_equal true, result[@forgery_material.id][:satisfied]
  end

  test "EXP potion: higher tier satisfies lower tier need" do
    potion_tier2 = Material.create!(
      name: "Basic Resonance Potion",
      material_type: "ResonatorEXP",
      category: "Resonator EXP Material",
      rarity: 2,
      exp_value: 1000
    )

    potion_tier3 = Material.create!(
      name: "Basic Resonance Potion",
      material_type: "ResonatorEXP",
      category: "Resonator EXP Material",
      rarity: 3,
      exp_value: 3000
    )

    # Need 1 EXP tier-2, own 0 tier-2 but own 1 tier-3 (3000 EXP)
    inventory = { potion_tier2.id => 0, potion_tier3.id => 1 }
    requirements = { potion_tier2.id => 1 }

    result = SynthesisService.new(inventory, requirements).reconcile_inventory

    assert_equal 0, result[potion_tier2.id][:deficit]
    assert_equal true, result[potion_tier2.id][:satisfied]
  end

  test "EXP potion: mixed tiers satisfy need" do
    potion_tier2 = Material.create!(
      name: "Basic Resonance Potion",
      material_type: "ResonatorEXP",
      category: "Resonator EXP Material",
      rarity: 2,
      exp_value: 1000
    )

    potion_tier3 = Material.create!(
      name: "Basic Resonance Potion",
      material_type: "ResonatorEXP",
      category: "Resonator EXP Material",
      rarity: 3,
      exp_value: 3000
    )

    potion_tier4 = Material.create!(
      name: "Basic Resonance Potion",
      material_type: "ResonatorEXP",
      category: "Resonator EXP Material",
      rarity: 4,
      exp_value: 8000
    )

    # Need 5 tier-2 equivalent (5000 EXP)
    # Own: 2 tier-2 (2000) + 1 tier-3 (3000) + 0 tier-4 = 5000 EXP total
    inventory = { potion_tier2.id => 2, potion_tier3.id => 1, potion_tier4.id => 0 }
    requirements = { potion_tier2.id => 5 }

    result = SynthesisService.new(inventory, requirements).reconcile_inventory

    assert_equal 0, result[potion_tier2.id][:deficit]
    assert_equal true, result[potion_tier2.id][:satisfied]
  end

  test "synthesis opportunity: detects when surplus can convert" do
    material_tier2 = Material.create!(
      name: "Cadence Seed",
      material_type: "ForgeryDrop",
      category: "Weapon and Skill Material",
      rarity: 2,
      item_group_id: "cadence-seed"
    )

    material_tier3 = Material.create!(
      name: "Cadence Bud",
      material_type: "ForgeryDrop",
      category: "Weapon and Skill Material",
      rarity: 3,
      item_group_id: "cadence-seed"
    )

    # Own 6 tier-2, need 3 tier-2 → surplus 3 can convert to 1 tier-3
    inventory = { material_tier2.id => 6, material_tier3.id => 0 }
    requirements = { material_tier2.id => 3, material_tier3.id => 1 }

    result = SynthesisService.new(inventory, requirements).reconcile_inventory

    # Tier-3 needs synthesis help
    assert_not_nil result[material_tier3.id][:synthesis_opportunity]
    assert_equal 1, result[material_tier3.id][:synthesis_opportunity][:can_convert]
  end

  test "no synthesis opportunity when no surplus" do
    material_tier2 = Material.create!(
      name: "Cadence Seed",
      material_type: "ForgeryDrop",
      category: "Weapon and Skill Material",
      rarity: 2,
      item_group_id: "cadence-seed"
    )

    material_tier3 = Material.create!(
      name: "Cadence Bud",
      material_type: "ForgeryDrop",
      category: "Weapon and Skill Material",
      rarity: 3,
      item_group_id: "cadence-seed"
    )

    # Own 3 tier-2, need exactly 3 tier-2 → no surplus
    inventory = { material_tier2.id => 3, material_tier3.id => 0 }
    requirements = { material_tier2.id => 3, material_tier3.id => 1 }

    result = SynthesisService.new(inventory, requirements).reconcile_inventory

    assert_nil result[material_tier3.id][:synthesis_opportunity]
  end
end
