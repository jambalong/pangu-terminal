require "test_helper"

class SkillLabelOverridesTest < ActiveSupport::TestCase
  PATH = Rails.root.join("config/skill_label_overrides.yml")

  test "overrides file maps resonator slugs to skill key => label hashes" do
    overrides = YAML.load_file(PATH)

    assert_not_empty overrides
    overrides.each do |slug, labels|
      assert_match(/\A[a-z0-9-]+\z/, slug)
      assert_kind_of Hash, labels
      assert_not_empty labels
      labels.each { |skill_key, label| assert_kind_of String, label, "#{slug}/#{skill_key}" }
    end
  end

  test "both consumers read the shared file instead of a copy" do
    [ "db/seeds/01_resonators.rb", "lib/tasks/forte_icons.rake" ].each do |file|
      source = Rails.root.join(file).read
      assert_includes source, "config/skill_label_overrides.yml", file
      assert_not_includes source, '"basic_attack" => "Normal-Attack"', "#{file} still has an inline copy"
    end
  end
end
