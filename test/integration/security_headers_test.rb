require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "pages send a content security policy with a script nonce" do
    get root_path

    csp = response.headers["Content-Security-Policy"]
    assert_match(/default-src 'self'/, csp)
    assert_match(/script-src 'self' 'nonce-[\w+\/=]+'/, csp)
    assert_match(/object-src 'none'/, csp)
    assert_match(/frame-ancestors 'none'/, csp)
    assert_no_match(/script-src[^;]*unsafe-inline/, csp)
  end

  test "importmap scripts carry the nonce from the policy" do
    get root_path

    nonce = response.headers["Content-Security-Policy"][/'nonce-([^']+)'/, 1]
    assert_select "script[type='importmap'][nonce=?]", nonce
  end

  test "each request gets a fresh nonce" do
    get root_path
    first = response.headers["Content-Security-Policy"][/'nonce-([^']+)'/, 1]
    get root_path
    second = response.headers["Content-Security-Policy"][/'nonce-([^']+)'/, 1]

    assert_not_equal first, second
  end

  test "permissions policy disables unused browser features" do
    get root_path

    policy = response.headers["Permissions-Policy"]
    assert_match(/camera=\(\)/, policy)
    assert_match(/microphone=\(\)/, policy)
    assert_match(/geolocation=\(\)/, policy)
  end
end
