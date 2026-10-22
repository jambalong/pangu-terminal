require "test_helper"
require "tmpdir"

class SeedGuardTest < ActiveSupport::TestCase
  setup do
    @root = Pathname(Dir.mktmpdir)
    (@root / "db/seeds").mkpath
    (@root / "config").mkpath
    (@root / "db/seeds.rb").write("# loader")
    (@root / "db/seeds/01_a.rb").write("A = 1")
    (@root / "config/skill_label_overrides.yml").write("x: {}")
    @guard = SeedGuard.new(root: @root)
  end

  teardown { FileUtils.remove_entry(@root) }

  def completing_seed
    -> { $SEED_COMPLETED = true }
  end

  test "checksum is stable for unchanged inputs" do
    assert_equal @guard.checksum, SeedGuard.new(root: @root).checksum
  end

  test "checksum changes when any seed input changes or is added" do
    before = @guard.checksum

    (@root / "db/seeds/01_a.rb").write("A = 2")
    after_edit = @guard.checksum
    (@root / "db/seeds/02_b.rb").write("B = 1")
    after_add = @guard.checksum
    (@root / "config/skill_label_overrides.yml").write("y: {}")
    after_yaml = @guard.checksum

    assert_equal 4, [ before, after_edit, after_add, after_yaml ].uniq.size
  end

  test "is stale until a checksum is recorded, then fresh" do
    assert @guard.stale?

    @guard.record!

    assert_not @guard.stale?
  end

  test "run seeds and records when stale" do
    ran = false

    outcome = @guard.run(seed: -> { ran = true; $SEED_COMPLETED = true })

    assert_equal :seeded, outcome
    assert ran
    assert_not @guard.stale?
  end

  test "run skips without seeding when nothing changed" do
    @guard.run(seed: completing_seed)
    ran = false

    outcome = @guard.run(seed: -> { ran = true; $SEED_COMPLETED = true })

    assert_equal :skipped, outcome
    assert_not ran
  end

  test "run seeds again after an input changes" do
    @guard.run(seed: completing_seed)
    (@root / "db/seeds/01_a.rb").write("A = 3")

    assert_equal :seeded, @guard.run(seed: completing_seed)
  end

  test "force seeds even when nothing changed" do
    @guard.run(seed: completing_seed)

    assert_equal :seeded, @guard.run(seed: completing_seed, force: true)
  end

  test "an incomplete seed records nothing so the next boot retries" do
    outcome = @guard.run(seed: -> { $SEED_COMPLETED = false })

    assert_equal :incomplete, outcome
    assert @guard.stale?
  end

  test "a seed that raises propagates and records nothing" do
    assert_raises(RuntimeError) { @guard.run(seed: -> { raise "boom" }) }

    assert @guard.stale?
  end
end
