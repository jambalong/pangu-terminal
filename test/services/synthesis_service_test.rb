require "test_helper"

class SynthesisServiceTest < ActiveSupport::TestCase
  test "calculates deficit correctly" do
    forgery_material = Material.create!(
      name: "Test Material",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 2,
      exp_value: 0
    )

    inventory = { forgery_material.id => 60 }
    requirements = { forgery_material.id => 100 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_equal 100, result[forgery_material.id][:needed]
    assert_equal 60, result[forgery_material.id][:owned]
    assert_equal 40, result[forgery_material.id][:deficit]
    assert_equal false, result[forgery_material.id][:fulfilled]
  end

  test "returns satisfied when owned >= needed" do
    forgery_material = Material.create!(
      name: "Test Material",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 2,
      exp_value: 0
    )

    inventory = { forgery_material.id => 100 }
    requirements = { forgery_material.id => 100 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_equal 0, result[forgery_material.id][:deficit]
    assert_equal true, result[forgery_material.id][:fulfilled]
  end

  test "returns satisfied when 0 owned and 0 needed" do
    forgery_material = Material.create!(
      name: "Test Material",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 2,
      exp_value: 0
    )

    inventory = { forgery_material.id => 0 }
    requirements = { forgery_material.id => 0 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_equal 0, result[forgery_material.id][:deficit]
    assert_equal true, result[forgery_material.id][:fulfilled]
  end

  test "exp potion of higher tier satisfies lower tier need" do
    potion_rarity2 = Material.create!(
      name: "EXP Potion Rarity 2",
      material_type: "resonator_exp",
      category: "Resonator EXP Material",
      rarity: 2,
      exp_value: 1000
    )

    potion_rarity3 = Material.create!(
      name: "EXP Potion Rarity 3",
      material_type: "resonator_exp",
      category: "Resonator EXP Material",
      rarity: 3,
      exp_value: 3000
    )

    # need 1 EXP rarity-2, own 0 rarity-2 but own 1 rarity-3 (3000 EXP)
    inventory = { potion_rarity2.id => 0, potion_rarity3.id => 1 }
    requirements = { potion_rarity2.id => 1 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_equal 0, result[potion_rarity2.id][:deficit]
    assert_equal true, result[potion_rarity2.id][:fulfilled]
  end

  test "exp potion of mixed tiers satisfy need" do
    potion_rarity2 = Material.create!(
      name: "EXP Potion Rarity 2",
      material_type: "resonator_exp",
      category: "Resonator EXP Material",
      rarity: 2,
      exp_value: 1000
    )

    potion_rarity3 = Material.create!(
      name: "EXP Potion Rarity 3",
      material_type: "resonator_exp",
      category: "Resonator EXP Material",
      rarity: 3,
      exp_value: 3000
    )

    potion_rarity4 = Material.create!(
      name: "EXP Potion Rarity 4",
      material_type: "resonator_exp",
      category: "Resonator EXP Material",
      rarity: 4,
      exp_value: 8000
    )

    # need 5 rarity-2 equivalent (5000 EXP)
    # own 2 rarity-2 (2000) + 1 rarity-3 (3000) + 0 rarity-4 = 5000 EXP total
    inventory = { potion_rarity2.id => 2, potion_rarity3.id => 1, potion_rarity4.id => 0 }
    requirements = { potion_rarity2.id => 5 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_equal 0, result[potion_rarity2.id][:deficit]
    assert_equal true, result[potion_rarity2.id][:fulfilled]
  end

  test "exp potion insufficient across all tiers" do
    potion_rarity2 = Material.create!(
      name: "EXP Potion Rarity 2",
      material_type: "resonator_exp",
      category: "Resonator EXP Material",
      rarity: 2,
      exp_value: 1000
    )

    # no higher rarity exp potions in inventory
    inventory = { potion_rarity2.id => 1 }
    requirements = { potion_rarity2.id => 5 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_equal 4, result[potion_rarity2.id][:deficit]
    assert_equal false, result[potion_rarity2.id][:fulfilled]
  end

  test "weapon exp does not satisfy resonator exp requirement" do
    resonator_potion_rarity2 = Material.create!(
      name: "Resonator EXP Potion Rarity 2",
      material_type: "resonator_exp",
      category: "Resonator EXP Material",
      rarity: 2,
      exp_value: 1000
    )

    weapon_potion_rarity3 = Material.create!(
      name: "Weapon EXP Potion Rarity 3",
      material_type: "weapon_exp",
      category: "Weapon EXP Material",
      rarity: 3,
      exp_value: 3000
    )

    # Need 1 resonator EXP rarity-2, own 0 resonator EXP rarity-2
    # but own 1 weapon EXP rarity-3 (3000 EXP) --> should not satisfy
    inventory = { resonator_potion_rarity2.id => 0, weapon_potion_rarity3.id => 1 }
    requirements = { resonator_potion_rarity2.id => 1 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_equal 1, result[resonator_potion_rarity2.id][:deficit]
    assert_equal false, result[resonator_potion_rarity2.id][:fulfilled]
  end

  test "synthesis opportunity detects when surplus can convert" do
    material_rarity2 = Material.create!(
      name: "Test Material Rarity 2",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 2,
      item_group_id: "test-group-id"
    )

    material_rarity3 = Material.create!(
      name: "Test Material Rarity 3",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 3,
      item_group_id: "test-group-id"
    )

    # Own 6 rarity-2, need 3 rarity-2 --> surplus 3 can convert to 1 rarity-3
    inventory = { material_rarity2.id => 6, material_rarity3.id => 0 }
    requirements = { material_rarity2.id => 3, material_rarity3.id => 1 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_not_nil result[material_rarity3.id][:craftable_count]
    assert_equal 1, result[material_rarity3.id][:craftable_count]
  end

  test "no synthesis opportunity when no surplus" do
    material_rarity2 = Material.create!(
      name: "Test Material Rarity 2",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 2,
      item_group_id: "test-group-id"
    )

    material_rarity3 = Material.create!(
      name: "Test Material Rarity 3",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 3,
      item_group_id: "test-group-id"
    )

    # Own 3 rarity-2, need exactly 3 rarity-2 --> no surplus
    inventory = { material_rarity2.id => 3, material_rarity3.id => 0 }
    requirements = { material_rarity2.id => 3, material_rarity3.id => 1 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_nil result[material_rarity3.id][:craftable_count]
  end

  test "no synthesis opportunity for lowest tier material" do
    material_rarity2 = Material.create!(
      name: "Test Material Rarity 2",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 2,
      item_group_id: "test-group-id"
    )

    inventory = { material_rarity2.id => 1 }
    requirements = { material_rarity2.id => 3 }

    result = SynthesisService.new(inventory, requirements).reconcile

    assert_nil result[material_rarity2.id][:craftable_count]
  end

  test "chain coverage covers deficit from single tier below" do
    material_rarity4 = Material.create!(
      name: "Test Material Rarity 4",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 4,
      item_group_id: "chain-group-id"
    )

    material_rarity5 = Material.create!(
      name: "Test Material Rarity 5",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 5,
      item_group_id: "chain-group-id"
    )

    # Need 2 rarity-5, own 0.
    # Own 9 rarity-4, need 0 -> surplus 9
    # pool: (0 + 9) / 3 = 3, capped at deficit 2 -> returns 2
    inventory = { material_rarity5.id => 0, material_rarity4.id => 9 }
    requirements = { material_rarity5.id => 2 }

    result = SynthesisService.new(inventory, requirements).chain_coverage

    assert_equal 2, result[material_rarity5.id]
  end

  test "chain coverage covers deficit across multiple tiers" do
    material_rarity3 = Material.create!(
      name: "Test Material Rarity 3",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 3,
      item_group_id: "chain-group-id"
    )

    material_rarity4 = Material.create!(
      name: "Test Material Rarity 4",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 4,
      item_group_id: "chain-group-id"
    )

    material_rarity5 = Material.create!(
      name: "Test Material Rarity 5",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 5,
      item_group_id: "chain-group-id"
    )

    # Need 2 rarity-5, own 0.
    # Own 3 rarity-4, need 0 -> surplus 3
    # Own 9 rarity-3, need 0 -> surplus 9
    # pool bottom-up: (0 + 9) / 3 = 3, (3 + 3) / 3 = 2 -> returns 2
    inventory = { material_rarity5.id => 0, material_rarity4.id => 3, material_rarity3.id => 9 }
    requirements = { material_rarity5.id => 2 }

    result = SynthesisService.new(inventory, requirements).chain_coverage

    assert_equal 2, result[material_rarity5.id]
  end

  test "chain coverage is capped at deficit, does not over-report" do
    material_rarity4 = Material.create!(
      name: "Test Material Rarity 4",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 4,
      item_group_id: "chain-group-id"
    )

    material_rarity5 = Material.create!(
      name: "Test Material Rarity 5",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 5,
      item_group_id: "chain-group-id"
    )

    # Need 1 rarity-5, own 0. Own 30 rarity-4 -> surplus 30 -> craftable 10
    # But deficit is only 1 — chain should report 1, not 10
    inventory = { material_rarity5.id => 0, material_rarity4.id => 30 }
    requirements = { material_rarity5.id => 1 }

    result = SynthesisService.new(inventory, requirements).chain_coverage

    assert_equal 1, result[material_rarity5.id]
  end

  test "chain coverage accounts for intermediate tier requirements" do
    material_rarity3 = Material.create!(
      name: "Test Material Rarity 3",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 3,
      item_group_id: "chain-group-id"
    )

    material_rarity4 = Material.create!(
      name: "Test Material Rarity 4",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 4,
      item_group_id: "chain-group-id"
    )

    material_rarity5 = Material.create!(
      name: "Test Material Rarity 5",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 5,
      item_group_id: "chain-group-id"
    )

    # Need 1 rarity-5, own 0.
    # Own 3 rarity-4, need 3 rarity-4 -> surplus 0
    # Own 9 rarity-3, need 0 -> surplus 9 -> crafts 3 rarity-4 -> craftable 1 rarity-5
    inventory = { material_rarity5.id => 0, material_rarity4.id => 3, material_rarity3.id => 9 }
    requirements = { material_rarity5.id => 1, material_rarity4.id => 3 }

    result = SynthesisService.new(inventory, requirements).chain_coverage

    assert_equal 1, result[material_rarity5.id]
  end

  test "chain coverage returns nil when deficit is zero" do
    material_rarity4 = Material.create!(
      name: "Test Material Rarity 4",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 4,
      item_group_id: "chain-group-id"
    )

    material_rarity5 = Material.create!(
      name: "Test Material Rarity 5",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 5,
      item_group_id: "chain-group-id"
    )

    inventory = { material_rarity5.id => 5, material_rarity4.id => 9 }
    requirements = { material_rarity5.id => 3 }

    result = SynthesisService.new(inventory, requirements).chain_coverage

    assert_nil result[material_rarity5.id]
  end

  test "chain coverage returns nil for material with no lower tier" do
    material_rarity2 = Material.create!(
      name: "Test Material Rarity 2",
      material_type: "forgery_drop",
      category: "Weapon and Skill Material",
      rarity: 2,
      item_group_id: "chain-group-id"
    )

    inventory = { material_rarity2.id => 0 }
    requirements = { material_rarity2.id => 5 }

    result = SynthesisService.new(inventory, requirements).chain_coverage

    assert_nil result[material_rarity2.id]
  end
end
