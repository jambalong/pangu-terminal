require "test_helper"

# The version is written by hand in a few places. Bump them all when you cut a
# release (the newest `## [x.y.z]` heading in CHANGELOG.md is the source of truth).
class VersionConsistencyTest < ActiveSupport::TestCase
  LATEST = File.read(Rails.root.join("CHANGELOG.md"))[/^## \[(\d+\.\d+\.\d+)\]/, 1]

  test "changelog has a released version" do
    assert LATEST
  end

  {
    "README.md" => /\*\*Version:\*\* (\d+\.\d+\.\d+)/,
    "app/views/pages/home.html.erb" => /SYSTEM ONLINE :: v(\d+\.\d+\.\d+)/,
    "app/views/pages/user_manual.html.erb" => /manual-version-tag">v(\d+\.\d+\.\d+)</
  }.each do |path, pattern|
    test "#{path} shows the latest changelog version" do
      assert_equal LATEST, File.read(Rails.root.join(path))[pattern, 1]
    end
  end
end
