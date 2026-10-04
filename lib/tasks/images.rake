namespace :images do
  desc "List seeded records whose image files are missing under public/ (run after db:seed)"
  task missing: :environment do
    missing = []

    [ Resonator, Weapon, Material ].each do |model|
      model.order(:name).find_each do |record|
        next if record.image_url.blank?
        path = Rails.root.join("public", record.image_url.delete_prefix("/"))
        missing << [ model.name, record.name, record.image_url ] unless path.exist?
      end
    end

    Resonator.order(:name).find_each do |resonator|
      icons = resonator.forte_icons || {}
      paths = (icons["skill_icons"] || {}).values + (icons["stat_icons"] || {}).values
      absent = paths.reject { |icon| Rails.root.join("public", icon.delete_prefix("/")).exist? }
      missing << [ "Forte icons", resonator.name, "#{absent.size} missing (run forte:download_skill_icons)" ] if absent.any?
    end

    if missing.empty?
      puts "All image files are present."
    else
      missing.group_by(&:first).each do |kind, rows|
        puts "#{kind} (#{rows.size}):"
        rows.each { |_, name, detail| puts "  #{name}: #{detail}" }
      end
      puts "\n#{missing.size} missing."
    end
  end
end
