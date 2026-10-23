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
    user = oauth_user(display_name: "player")
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
    assert_equal "player", User.new(display_name: "player", email: "a@example.com").shown_name
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

  test "generated display names are lowercase, valid and fit the cap" do
    50.times do
      name = User.generate_display_name
      assert_match User::DISPLAY_NAME_FORMAT, name
      assert_includes User::DISPLAY_NAME_LENGTH, name.length
    end
  end

  test "display_name is lowercased and stripped" do
    user = oauth_user(display_name: "  Rover-Fan ")
    user.save!
    assert_equal "rover-fan", user.reload.display_name
  end

  test "display_name length is capped" do
    assert oauth_user(display_name: "a" * 16).valid?
    assert oauth_user(display_name: "a" * 17).invalid?
    assert oauth_user(display_name: "ab").invalid?
  end

  test "display_name rejects spaces and symbols" do
    [ "two words", "bad!name", "-lead" ].each do |name|
      assert oauth_user(display_name: name).invalid?, "#{name.inspect} should be invalid"
    end
  end

  test "blank display_name is stored as nil" do
    user = oauth_user(display_name: "  ")
    user.save!
    assert_nil user.reload.display_name
  end

  test "an older long display_name stays valid until it is changed" do
    user = oauth_user
    user.save!
    user.update_column(:display_name, "john alvin ambalong")

    assert user.reload.update(sol3_phase: 4)
    assert_not user.update(display_name: "john alvin ambalong jr")
  end
end
