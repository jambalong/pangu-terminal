require "test_helper"

class PlansHelperTest < ActionView::TestCase
  test "forte_configs returns array of forte configuration hashes" do
    configs = forte_configs
    assert configs.is_a?(Array)
    assert configs.any? { |c| c[:key] == "basic_attack" }
    assert configs.any? { |c| c[:key] == "forte_circuit" }
  end

  test "format_node_name humanizes and titleizes key" do
    assert_equal "Basic Attack", format_node_name("basic_attack")
    assert_equal "Forte Circuit", format_node_name(:forte_circuit)
  end
end
