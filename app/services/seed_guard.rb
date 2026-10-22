# Skips the (idempotent but slow) game-data seed when none of its inputs changed
# since the last successful run. bin/docker-entrypoint calls it on every boot.
#
# The checksum is stored in ar_internal_metadata and written only after the seed
# reports success ($SEED_COMPLETED, set at the end of db/seeds.rb). db/seeds.rb
# swallows failures with ActiveRecord::Rollback, so the exit status alone cannot
# tell success from failure.
class SeedGuard
  METADATA_KEY = :seeds_checksum
  INPUTS = %w[db/seeds.rb db/seeds/*.rb config/skill_label_overrides.yml].freeze

  def initialize(root: Rails.root)
    @root = Pathname(root)
  end

  def checksum
    files = INPUTS.flat_map { |pattern| Dir[@root.join(pattern)] }.sort
    parts = files.map { |file| "#{Pathname(file).relative_path_from(@root)}\0#{File.read(file)}" }
    Digest::SHA256.hexdigest(parts.join("\0"))
  end

  def stale?
    metadata[METADATA_KEY] != checksum
  end

  def record!
    metadata[METADATA_KEY] = checksum
  end

  # Returns :skipped (inputs unchanged), :seeded (ran and recorded) or :incomplete
  # (ran but did not finish; nothing recorded, so the next boot retries).
  def run(seed:, force: false)
    return :skipped unless force || stale?

    $SEED_COMPLETED = false
    seed.call
    return :incomplete unless $SEED_COMPLETED

    record!
    :seeded
  end

  private

  def metadata
    ActiveRecord::Base.connection_pool.internal_metadata
  end
end
