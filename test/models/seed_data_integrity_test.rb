require "test_helper"

# Guards against half-finished game data updates: every Resonator and weapon
# must resolve to a complete set of materials after seeding.
class SeedDataIntegrityTest < ActiveSupport::TestCase
  # Seeded weapons whose enemy-drop set is not known yet. Remove an entry once
  # it is mapped in db/seeds/05_mapping_tables.rb (see docs/ROADMAP.md).
  WEAPONS_MISSING_ENEMY_DROP_MAP = [ "Fusion Accretion" ].freeze

  test "every resonator maps boss, flower, four enemy drops and a weekly boss material" do
    Resonator.find_each do |resonator|
      maps = ResonatorMaterialMap.where(resonator: resonator)
      counts = maps.group(:material_type).count

      assert_equal 1, counts["boss_drop"], "#{resonator.name} needs one boss_drop"
      assert_equal 1, counts["flower"], "#{resonator.name} needs one flower"
      assert_equal 4, counts["enemy_drop"], "#{resonator.name} needs four enemy_drop rarities"
      assert_equal 1, counts["weekly_boss_drop"], "#{resonator.name} needs one weekly_boss_drop"
    end
  end

  test "every weapon maps four enemy drop rarities" do
    Weapon.where.not(name: WEAPONS_MISSING_ENEMY_DROP_MAP).find_each do |weapon|
      assert_equal [ 2, 3, 4, 5 ],
        WeaponMaterialMap.where(weapon: weapon, material_type: "enemy_drop").order(:rarity).pluck(:rarity),
        "#{weapon.name} needs enemy_drop rarities 2-5"
    end
  end

  test "every weapon type has four forgery rarities for each region" do
    Weapon.distinct.pluck(:weapon_type).each do |weapon_type|
      %w[base lahai_roi].each do |region|
        rarities = WeaponTypeMaterial.where(weapon_type: weapon_type, region: region).order(:rarity).pluck(:rarity)
        assert_equal [ 2, 3, 4, 5 ], rarities, "#{weapon_type}/#{region} forgery drops incomplete"
      end
    end
  end

  test "every boss and weekly challenge material has a source with drop rates for all phases" do
    Material.where(material_type: %w[boss_drop weekly_boss_drop]).where.not(name: "Mysterious Code").find_each do |material|
      assert material.sources.any?, "#{material.name} has no source"

      material.sources.each do |source|
        assert_equal (1..8).to_a, source.drop_rates.order(:sol3_phase).pluck(:sol3_phase),
          "#{source.name} is missing drop rates"
      end
    end
  end

  test "regional planner lists only name existing records" do
    assert_empty ResonatorAscensionPlanner::LAHAI_ROI_RESONATORS - Resonator.pluck(:name)
    assert_empty WeaponAscensionPlanner::LAHAI_ROI_WEAPONS - Weapon.pluck(:name)
  end
end
