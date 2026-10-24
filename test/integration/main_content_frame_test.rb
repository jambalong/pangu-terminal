require "test_helper"

# The layout wraps full page loads in one "main_content" frame; a Turbo frame
# request gets only the view, so the view supplies the frame. Either way the
# document must contain exactly one, with no nested duplicates.
class MainContentFrameTest < ActionDispatch::IntegrationTest
  FRAME_HEADER = { "Turbo-Frame" => "main_content" }.freeze

  setup do
    @user = User.create!(email: "frame@example.com", password: "password123", sol3_phase: 3)
    sign_in @user
  end

  def paths
    [ authenticated_root_path, plans_path, inventory_items_path, optimizer_path ]
  end

  test "full page loads contain exactly one main_content frame" do
    (paths + [ root_path, privacy_path ]).each do |path|
      get path
      assert_select "turbo-frame#main_content", count: 1
      assert_select "turbo-frame#main_content turbo-frame#main_content", count: 0, message: "#{path} nests the frame"
    end
  end

  test "turbo frame requests return exactly one main_content frame" do
    (paths + [ root_path, privacy_path ]).each do |path|
      get path, headers: FRAME_HEADER
      assert_select "turbo-frame#main_content", count: 1
    end
  end

  test "no page repeats an element id" do
    paths.each do |path|
      get path
      ids = css_select("[id]").map { |node| node["id"] }
      assert_equal [], ids.tally.select { |_id, count| count > 1 }.keys, "#{path} repeats ids"
    end
  end
end
