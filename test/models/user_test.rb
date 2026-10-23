require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.new(email: "phase@example.com", password: "password123")
  end

  test "sol3_phase may be blank" do
    @user.sol3_phase = nil
    assert @user.valid?
  end

  test "sol3_phase accepts every known phase" do
    DropRate::SOL3_PHASES.each do |phase|
      @user.sol3_phase = phase
      assert @user.valid?, "phase #{phase} should be valid"
    end
  end

  test "sol3_phase rejects phases outside the known range" do
    [ 0, DropRate::SOL3_PHASES.last + 1, 99, -1 ].each do |phase|
      @user.sol3_phase = phase
      assert @user.invalid?, "phase #{phase} should be invalid"
      assert @user.errors[:sol3_phase].any?
    end
  end

  def oauth_user(**attrs)
    User.new(**attrs).tap { |user| user.identities.build(provider: "discord", uid: SecureRandom.hex(4)) }
  end

  test "an OAuth user needs neither email nor password" do
    user = oauth_user(display_name: "Player")
    assert user.valid?, user.errors.full_messages.to_sentence
    assert user.save
    assert_nil user.reload.email
  end

  test "several OAuth users without email can coexist" do
    assert oauth_user.save
    assert oauth_user.save
  end

  test "a user with no identity still needs email and password" do
    user = User.new
    assert user.invalid?
    assert user.errors[:email].any?
    assert user.errors[:password].any?
  end

  test "blank email is stored as NULL" do
    user = oauth_user(email: "  ")
    user.save!
    assert_nil user.reload.email
  end

  test "a password user cannot blank their email" do
    user = User.create!(email: "keep@example.com", password: "password123")
    user.email = ""
    assert user.invalid?
    assert user.errors[:email].any?
  end

  test "an OAuth user who sets a password must confirm it and then needs an email" do
    user = oauth_user
    user.save!
    user.update!(password: "password123", password_confirmation: "password123", email: "later@example.com")
    assert user.reload.password?
    user.email = nil
    assert user.invalid?
  end

  test "shown_name prefers display_name, then the email local part" do
    assert_equal "Player", User.new(display_name: "Player", email: "a@example.com").shown_name
    assert_equal "a", User.new(email: "a@example.com").shown_name
    assert_equal "Account", User.new.shown_name
  end

  test "can_unlink? needs another identity or an email and password" do
    user = oauth_user
    user.save!
    identity = user.identities.first
    assert_not user.can_unlink?(identity)

    user.identities.create!(provider: "google_oauth2", uid: "x")
    assert user.can_unlink?(identity)
  end
end
