require "test_helper"

class CrawlerFilesTest < ActiveSupport::TestCase
  test "robots.txt keeps accounts, the app and the API out and lists the sitemap" do
    robots = Rails.root.join("public/robots.txt").read

    %w[ /app/ /users/ /api/ /settings /sign-in ].each do |path|
      assert_includes robots, "Disallow: #{path}"
    end
    assert_includes robots, "Sitemap: https://panguterminal.ambalong.dev/sitemap.xml"
  end

  test "sitemap lists only public pages" do
    sitemap = Rails.root.join("public/sitemap.xml").read

    %w[ / /user-manual /privacy ].each { |path| assert_includes sitemap, "https://panguterminal.ambalong.dev#{path}</loc>" }
    assert_no_match(%r{/app/|/users/|/api/}, sitemap)
  end

  test "manifest icons exist" do
    JSON.parse(Rails.root.join("public/manifest.json").read)["icons"].each do |icon|
      assert Rails.root.join("public#{icon["src"]}").exist?, "#{icon["src"]} is missing"
    end
  end
end
