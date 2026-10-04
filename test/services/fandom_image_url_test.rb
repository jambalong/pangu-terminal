require "test_helper"

class FandomImageUrlTest < ActiveSupport::TestCase
  BASE = "https://static.wikia.nocookie.net/wutheringwaves/images".freeze

  def url_for(name, prefix, **options)
    FandomImageUrl.call(name: name, prefix: prefix, base: BASE, **options)
  end

  test "builds hashed paths matching real wiki URLs" do
    assert_equal "#{BASE}/a/ac/Resonator_Qingxiao.png/revision/latest", url_for("Qingxiao", "Resonator_")
    assert_equal "#{BASE}/8/8e/Resonator_Hiyuki.png/revision/latest", url_for("Hiyuki", "Resonator_")
    assert_equal "#{BASE}/2/20/Weapon_Azure_Oath.png/revision/latest", url_for("Azure Oath", "Weapon_")
  end

  test "keeps apostrophes literal in the hash and the URL" do
    assert_equal "#{BASE}/8/87/Item_Forged_Empyrean's_Sigh.png/revision/latest",
      url_for("Forged Empyrean's Sigh", "Item_")
  end

  test "drops colons from names" do
    assert_equal "#{BASE}/0/0b/Resonator_Yangyang_Xuanling.png/revision/latest",
      url_for("Yangyang: Xuanling", "Resonator_")
  end

  test "uses wiki_names for records whose wiki file differs" do
    assert_equal "#{BASE}/4/47/Resonator_Rover.png/revision/latest",
      url_for("Rover-Electro", "Resonator_", wiki_names: { "Rover-Electro" => "Rover" })
  end

  test "tolerates a trailing slash on the base URL" do
    assert_equal url_for("Qingxiao", "Resonator_"),
      FandomImageUrl.call(name: "Qingxiao", prefix: "Resonator_", base: "#{BASE}/")
  end
end
