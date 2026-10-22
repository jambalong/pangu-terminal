require "test_helper"

class WeaponTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "region defaults to base and accepts the known regions" do
    record = Weapon.new(name: "Region Probe Blade", weapon_type: "Sword")
    assert_equal "base", record.region
    assert record.valid?, record.errors.full_messages.to_sentence

    ForgeryRegion::REGIONS.each do |region|
      record.region = region
      assert record.valid?
    end
  end

  test "region rejects unknown values" do
    record = Weapon.new(name: "Region Probe Blade", weapon_type: "Sword", region: "atlantis")
    assert record.invalid?
    assert record.errors[:region].any?
  end
end
