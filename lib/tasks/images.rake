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

  desc "Download missing Resonator/weapon/material images from config/image_sources.yml (KIND=resonators|weapons|materials, DRY_RUN=1)"
  task download: :environment do
    require "net/http"
    require "tempfile"
    require "yaml"

    config = YAML.safe_load_file(Rails.root.join("config/image_sources.yml")) || {}
    templates = config["templates"] || {}
    overrides = config["overrides"] || {}
    fandom = config["fandom"] || {}
    wiki_names = config["wiki_names"] || {}
    dry_run = ENV["DRY_RUN"].present?
    magick = %w[magick convert].find { |bin| system("which #{bin} > /dev/null 2>&1") }

    abort "ImageMagick (magick or convert) is required." unless magick || dry_run

    kinds = { "resonators" => Resonator, "weapons" => Weapon, "materials" => Material }
    kinds = kinds.slice(ENV["KIND"]) if ENV["KIND"].present?
    abort "Unknown KIND #{ENV['KIND'].inspect}" if kinds.empty?

    fetch = lambda do |url, limit = 4|
      raise "too many redirects" if limit.zero?
      response = Net::HTTP.get_response(URI(url))
      case response
      when Net::HTTPSuccess then response.body
      when Net::HTTPRedirection then fetch.call(URI.join(url, response["location"]).to_s, limit - 1)
      else raise "HTTP #{response.code}"
      end
    end

    saved = failed = skipped = 0

    kinds.each do |kind, model|
      model.order(:name).find_each do |record|
        next if record.image_url.blank?

        dest = Rails.root.join("public", record.image_url.delete_prefix("/"))
        next if dest.exist?

        slug = File.basename(record.image_url, ".*")
        url = overrides[record.name].presence
        if url.nil? && fandom["base"].present? && fandom.dig("prefixes", kind).present?
          url = FandomImageUrl.call(
            name: record.name, prefix: fandom.dig("prefixes", kind), base: fandom["base"], wiki_names: wiki_names
          )
        end
        url ||= templates[kind].presence&.gsub("{slug}", slug)&.gsub("{name}", ERB::Util.url_encode(record.name))

        if url.nil?
          puts "  no source for #{kind}/#{record.name}"
          skipped += 1
          next
        end

        if dry_run
          puts "  would fetch #{url} -> #{record.image_url}"
          next
        end

        begin
          Tempfile.create([ "image", File.extname(URI(url).path) ]) do |tmp|
            tmp.binmode
            tmp.write(fetch.call(url))
            tmp.flush
            FileUtils.mkdir_p(dest.dirname)
            ok = system(magick, tmp.path, "-resize", "256x256", "-background", "none",
                        "-gravity", "center", "-extent", "256x256", "PNG:#{dest}")
            raise "ImageMagick conversion failed" unless ok
          end
          puts "  saved #{record.image_url}"
          saved += 1
        rescue => e
          puts "  FAILED #{kind}/#{record.name}: #{e.message}"
          failed += 1
        end
      end
    end

    puts "Done. saved=#{saved} failed=#{failed} no_source=#{skipped}"
  end
end
