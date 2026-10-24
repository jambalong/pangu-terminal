require "test_helper"

class SemanticLayoutTest < ActionDispatch::IntegrationTest
  test "pages declare their language" do
    [ root_path, user_manual_path, privacy_path, new_user_session_path ].each do |path|
      get path
      assert_select "html[lang=en]", true, "#{path} needs <html lang>"
    end
  end

  test "layout has a skip link to the main landmark and a labelled nav" do
    get root_path

    assert_select "a.skip-link[href='#main-content']", text: "Skip to main content"
    assert_select "main#main-content"
    assert_select "nav[aria-label=Main]"
  end

  test "flash container is a polite live region and alerts announce themselves" do
    get new_user_session_path
    assert_select "#flash-container[role=status][aria-live=polite]"

    post user_session_path, params: { user: { email: "nobody@example.com", password: "wrong-password" } }
    assert_select "#flash-container .flash-message.alert[role=alert]"
  end

  test "form errors are announced" do
    user = User.create!(email: "semantic@example.com", password: "password123")
    sign_in user

    patch update_user_registration_path, params: { user: { display_name: "no good name!" } }

    assert_select "#error_explanation[role=alert]"
  end

  test "sign-in and settings each have one h1" do
    get new_user_session_path
    assert_select "h1", count: 1

    sign_in User.create!(email: "semantic_h1@example.com", password: "password123")
    get edit_user_registration_path
    assert_select "h1", count: 1
  end

  test "the manual has no nested navs" do
    get user_manual_path

    assert_select "nav nav", count: 0
  end

  test "error messages stay until dismissed and notices fade on their own" do
    post user_session_path, params: { user: { email: "nobody@example.com", password: "wrong-password" } }
    assert_select ".flash-message.alert[data-flash-persist-value=true] button.flash-close"

    user = User.create!(email: "flash@example.com", password: "password123")
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
    follow_redirect!
    assert_select ".flash-message.notice[data-flash-persist-value=false]"
    assert_select ".flash-message.notice button.flash-close", count: 0
  end
end
