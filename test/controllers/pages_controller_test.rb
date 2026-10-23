require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET / returns success" do
    get root_path
    assert_response :success
  end

  test "GET /privacy returns success without signing in" do
    get privacy_path
    assert_response :success
    assert_select "h1", text: "Privacy Policy"
  end

  test "GET /user-manual returns success" do
    get user_manual_path
    assert_response :success
  end

  test "pages carry description, canonical and social tags" do
    get root_path

    assert_select "meta[name=description][content*='Wuthering Waves']"
    assert_select "link[rel=canonical][href='https://panguterminal.ambalong.dev/']"
    assert_select "meta[property='og:title'][content='Pangu Terminal']"
    assert_select "meta[property='og:image'][content='https://panguterminal.ambalong.dev/favicon.png']"
    assert_select "meta[name='twitter:card'][content=summary]"
  end

  test "privacy page sets its own title and canonical URL" do
    get privacy_path

    assert_select "title", text: "Privacy Policy: Pangu Terminal"
    assert_select "link[rel=canonical][href$='/privacy']"
  end

  test "user manual carries social tags too" do
    get user_manual_path

    assert_select "meta[property='og:title'][content='User Manual: Pangu Terminal']"
    assert_select "link[rel=canonical][href$='/user-manual']"
  end

  test "canonical host follows APP_HOST" do
    original = ENV["APP_HOST"]
    ENV["APP_HOST"] = "example.test"
    get root_path
    assert_select "link[rel=canonical][href='https://example.test/']"
  ensure
    ENV["APP_HOST"] = original
  end
end
