require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  test "provider must be a known provider" do
    user = User.create!(email: "idm@example.com", password: "password123")
    assert_not user.identities.build(provider: "github", uid: "1").valid?
  end

  test "provider and uid are unique together" do
    user = User.create!(email: "idm2@example.com", password: "password123")
    other = User.create!(email: "idm3@example.com", password: "password123")
    user.identities.create!(provider: "discord", uid: "1")

    assert_not other.identities.build(provider: "discord", uid: "1").valid?
    assert other.identities.build(provider: "google_oauth2", uid: "1").valid?
  end

  test "a user has one identity per provider" do
    user = User.create!(email: "idm4@example.com", password: "password123")
    user.identities.create!(provider: "discord", uid: "1")

    assert_not user.identities.build(provider: "discord", uid: "2").valid?
  end
end
