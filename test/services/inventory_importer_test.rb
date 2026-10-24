require "test_helper"

class InventoryImporterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "importer@example.com", password: "password123")
    @shell = Material.find_by!(name: "Shell Credit")
    @core = Material.find_by!(name: "Basic Energy Core")
  end

  def import(text) = InventoryImporter.call(user: @user, content: text)
  def quantity_of(material) = @user.inventory_items.find_by(material: material)&.quantity

  test "creates and updates quantities from CSV by key or by name" do
    @user.inventory_item_for(@core).update!(quantity: 3)

    result = import("key,name,quantity\nshell_credit,Shell Credit,120000\n")
    assert_equal 120_000, quantity_of(@shell)
    assert_equal 1, result[:updated]

    result = import("name,quantity\nBasic Energy Core,40\n")
    assert_equal 40, quantity_of(@core)
    assert_equal [ 1, [] ], [ result[:updated], result[:skipped] ]
  end

  test "an identifier that is neither a key nor a name is not guessed at" do
    @user.inventory_item_for(@core).update!(quantity: 3)

    result = import("key,quantity\nbasic energy cores,40\n")

    assert_equal 3, quantity_of(@core)
    assert_equal 1, result[:skipped].size
  end

  test "matches names case-insensitively and ignores extra spaces" do
    import("name,quantity\n  shell   CREDIT ,55\n")

    assert_equal 55, quantity_of(@shell)
  end

  test "JSON in the API shape works" do
    result = import(%({"shell_credit": 10, "basic_energy_core": "25"}))

    assert_equal [ 10, 25 ], [ quantity_of(@shell), quantity_of(@core) ]
    assert_equal 2, result[:updated]
  end

  test "thousands separators and integral floats are accepted" do
    import(%(key,quantity\nshell_credit,"1,200"\nbasic_energy_core,5.0\n))

    assert_equal [ 1200, 5 ], [ quantity_of(@shell), quantity_of(@core) ]
  end

  test "unchanged rows are counted and not rewritten" do
    @user.inventory_item_for(@shell).update!(quantity: 10)
    before = @user.inventory_items.find_by(material: @shell).updated_at

    result = import("key,quantity\nshell_credit,10\nbasic_energy_core,0\n")

    assert_equal [ 0, 2 ], [ result[:updated], result[:unchanged] ]
    assert_equal before, @user.inventory_items.find_by(material: @shell).updated_at
    assert_nil quantity_of(@core), "a zero for a material with no row does not create one"
  end

  test "materials the file does not mention are left alone" do
    @user.inventory_item_for(@core).update!(quantity: 9)

    import("key,quantity\nshell_credit,1\n")

    assert_equal 9, quantity_of(@core)
  end

  test "bad rows are skipped with a reason and the good rows still apply" do
    result = import(<<~CSV)
      key,quantity
      shell_credit,100
      nonsense_material,5
      basic_energy_core,-4
      basic_energy_core,lots
      ,7
      shell_credit,99999999999
    CSV

    assert_equal 100, quantity_of(@shell)
    reasons = result[:skipped].map { |s| s[:reason] }
    assert reasons.any? { |r| r.include?("unknown material") }
    assert reasons.count { |r| r.include?("not a whole number") } >= 2
    assert reasons.any? { |r| r.include?("no material name") }
    assert reasons.any? { |r| r.include?("larger than") }
    assert_includes result[:skipped].map { |s| s[:where] }, "line 3"
  end

  test "a material listed twice takes the later value and says so" do
    result = import("key,quantity\nshell_credit,1\nshell_credit,2\n")

    assert_equal 2, quantity_of(@shell)
    assert result[:skipped].any? { |s| s[:reason].include?("listed again later") }
  end

  test "an unreadable file changes nothing" do
    @user.inventory_item_for(@shell).update!(quantity: 5)

    result = import("{broken")

    assert result[:error]
    assert_equal 5, quantity_of(@shell)
  end

  test "a header with no rows, or an empty list, is an error not a success" do
    assert_match(/no rows to import/, import("key,name,quantity\n")[:error])
    assert_match(/no rows to import/, import("[]")[:error])
    assert_match(/no rows to import/, import("{}")[:error])
  end

  test "too many rows are refused" do
    big = "key,quantity\n" + ("shell_credit,1\n" * (InventoryImporter::MAX_ROWS + 1))

    assert_match(/too many rows/, import(big)[:error])
  end

  test "only the importing user's inventory changes" do
    other = User.create!(email: "importer_other@example.com", password: "password123")
    other.inventory_item_for(@shell).update!(quantity: 77)

    import("key,quantity\nshell_credit,1\n")

    assert_equal 77, other.inventory_items.find_by(material: @shell).quantity
  end
end
