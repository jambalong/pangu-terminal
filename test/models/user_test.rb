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
end
