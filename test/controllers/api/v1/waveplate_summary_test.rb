require "test_helper"

class Api::V1::WaveplateSummaryTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "waveplate_summary@example.com", password: "password123")
    @user.sol3_phase = 3
    @user.save!
    @user.send(:initialize_inventory)

    @other_user = User.create!(email: "waveplate_summary_other@example.com", password: "password123")

    @api_key = @user.api_keys.create!(name: "Test Key")
    @raw_token = @api_key.raw_token

    @lf_whisperin_core = Material.find_by!(name: "LF Whisperin Core")
    @shell_credit = Material.find_by!(name: "Shell Credit")
    @weapon = Weapon.find_by!(name: "Kumokiri")

    @plan = Plan.create!(
      user: @user,
      subject: @weapon,
      subject_type: "Weapon",
      plan_data: {
        "input" => {},
        "output" => {
          @lf_whisperin_core.id => 6,
          @shell_credit.id => 25480
        }
      }
    )

    @other_plan = Plan.create!(
      user: @other_user,
      subject: @weapon,
      subject_type: "Weapon",
      plan_data: { "input" => {}, "output" => {} }
    )
  end

  test "returns 401 with no token" do
    get waveplate_summary_api_v1_plan_path(@plan), headers: {}
    assert_response :unauthorized
  end

  test "returns 401 with invalid token" do
    get waveplate_summary_api_v1_plan_path(@plan),
      headers: { "Authorization" => "Bearer #{SecureRandom.hex(16)}" }
    assert_response :unauthorized
  end

  test "returns 404 for plan belonging to another user" do
    get waveplate_summary_api_v1_plan_path(@other_plan), headers: auth_headers
    assert_response :not_found
  end

  test "returns 404 for non-existent plan id" do
    get waveplate_summary_api_v1_plan_path(id: 0), headers: auth_headers
    assert_response :not_found
  end

  test "returns 422 when sol3_phase is not set" do
    @user.update!(sol3_phase: nil)
    get waveplate_summary_api_v1_plan_path(@plan), headers: auth_headers
    assert_response :unprocessable_entity
    assert_equal "SOL3 Phase not set. Use PATCH /api/v1/profile to set it.", JSON.parse(response.body)["error"]
  end

  test "returns 200 for own plan with sol3_phase set" do
    get waveplate_summary_api_v1_plan_path(@plan), headers: auth_headers
    assert_response :ok
  end

  test "returns json content type" do
    get waveplate_summary_api_v1_plan_path(@plan), headers: auth_headers
    assert_includes response.content_type, "application/json"
  end

  test "only includes materials with active deficit and farmable source" do
    # shell_credit has no farmable waveplate source, lf_whisperin_core does
    get waveplate_summary_api_v1_plan_path(@plan), headers: auth_headers

    body = JSON.parse(response.body)
    assert_not_includes body.keys, "lf_whisperin_core"
  end

  test "returns empty hash when all deficits are covered" do
    @user.inventory_item_for(@lf_whisperin_core).update!(quantity: 10)
    @user.inventory_item_for(@shell_credit).update!(quantity: 30000)

    get waveplate_summary_api_v1_plan_path(@plan), headers: auth_headers

    assert_equal({}, JSON.parse(response.body))
  end

  test "each entry has the expected fields" do
    get waveplate_summary_api_v1_plan_path(@plan), headers: auth_headers

    entry = JSON.parse(response.body)["shell_credit"]
    assert_not_nil entry
    assert_includes entry.keys, "deficit"
    assert_includes entry.keys, "source_type"
    assert_includes entry.keys, "sources"
    assert_includes entry.keys, "estimated_runs"
    assert_includes entry.keys, "waveplate_cost"
  end

  test "sources is an array of location names" do
    get waveplate_summary_api_v1_plan_path(@plan), headers: auth_headers

    sources = JSON.parse(response.body)["shell_credit"]["sources"]
    assert sources.is_a?(Array)
    assert sources.all? { |s| s.is_a?(String) }
  end

  test "deficit reflects shortfall after reconciliation" do
    get waveplate_summary_api_v1_plan_path(@plan), headers: auth_headers

    assert_equal 25480, JSON.parse(response.body)["shell_credit"]["deficit"]
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@raw_token}" }
  end
end
