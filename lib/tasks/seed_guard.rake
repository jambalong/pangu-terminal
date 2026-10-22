namespace :db do
  namespace :seed do
    desc "Run db:seed only if the seed files changed since the last successful run (FORCE_SEED=1 to force)"
    task if_changed: :environment do
      seed = -> { Rake::Task["db:seed"].invoke }

      begin
        outcome = SeedGuard.new.run(seed: seed, force: ENV["FORCE_SEED"] == "1")
      rescue ActiveRecord::ActiveRecordError => e
        # The guard itself must never block a boot: fall back to the plain seed.
        warn "SeedGuard unavailable (#{e.class}: #{e.message.truncate(200)}); running db:seed."
        seed.call
        outcome = :fallback
      end

      case outcome
      when :skipped then puts "Seeds unchanged since the last successful run; skipping."
      when :incomplete then warn "Seeding did not complete; checksum not recorded, it will retry on the next boot."
      end
    end
  end
end
