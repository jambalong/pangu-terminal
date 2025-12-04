# This block ensures that if ANY file fails, the whole database
# rolls back to a clean state, preventing "half-seeded" data.
ActiveRecord::Base.transaction do
  puts "🌱 Seeding Database..."

  $SEED_DATA = {}

  # 1. Find all .rb files in the db/seeds directory
  # 2. Sort them (so 01 runs before 02)
  # 3. Load them
  Dir[Rails.root.join("db", "seeds", "*.rb")].sort.each do |file|
    puts "  --> Processing #{File.basename(file)}..."

    # 'load' executes the code in the file
    load file
  end

  puts "✅ SEEDING COMPLETED!"
rescue StandardError => e
  puts "❌ SEEDING FAILED!"
  puts "Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  # Re-raise the error to ensure the transaction rolls back
  raise ActiveRecord::Rollback
end
