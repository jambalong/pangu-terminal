require "net/http"

namespace :forte do
  STAT_ICON_URLS = {
    "atk"           => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertyredattack_UI.avif",
    "crit_rate"     => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertyredbaoji_UI.avif",
    "crit_dmg"      => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertyredcrit_UI.avif",
    "hp"            => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertygreenlife_UI.avif",
    "def"           => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertygreendefense_UI.avif",
    "healing_bonus" => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertygreencure_UI.avif",
    "aero_dmg"      => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertyredwind_UI.avif",
    "fusion_dmg"    => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertyredhot_UI.avif",
    "glacio_dmg"    => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertyredice_UI.avif",
    "havoc_dmg"     => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertyreddark_UI.avif",
    "spectro_dmg"   => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertyredlight_UI.avif",
    "electro_dmg"   => "https://static-cloudflare-f8p1t7z8.wutheringwaves.wiki/transform/kuro/gameclient/Content/Aki/UI/UIResources/Common/Image/IconAttribute/T_Iconpropertyredmine_UI.avif"
  }.freeze

  SKILL_LABELS_RAKE = {
    "basic_attack"         => "Basic-Attack",
    "resonance_skill"      => "Resonance-Skill",
    "forte_circuit"        => "Forte-Circuit",
    "resonance_liberation" => "Resonance-Liberation",
    "intro_skill"          => "Intro-Skill",
    "inherent_skill_1"     => "Inherent-Skill-1",
    "inherent_skill_2"     => "Inherent-Skill-2"
  }.freeze

  SKILL_LABEL_OVERRIDES_RAKE = {
    "luuk-herssen" => { "basic_attack" => "Normal-Attack" },
    "cartethyia"   => { "basic_attack" => "Normal-Attack" },
    "ciaccona"     => { "basic_attack" => "Normal-Attack" },
    "lupa"         => { "basic_attack" => "Normal-Attack" },
    "zani"         => { "basic_attack" => "Normal-Attack" },
    "youhu"        => { "basic_attack" => "Normal-Attack" },
    "shorekeeper"  => { "resonance_skill" => "Resonance-Skill-" }
  }.freeze

  WUTHERINGLAB_BASE = "https://wutheringlab.com/wp-content/uploads"

  desc "Download stat bonus icons from wuwa.wiki into public/images/forte/stats/"
  task download_stat_icons: :environment do
    dest = Rails.root.join("public/images/forte/stats")
    FileUtils.mkdir_p(dest)

    STAT_ICON_URLS.each do |stat_key, url|
      dest_file = dest.join("#{stat_key}.avif")
      if dest_file.exist?
        puts "  skip #{stat_key}.avif (already exists)"
        next
      end

      puts "  downloading #{stat_key}..."
      response = Net::HTTP.get_response(URI(url))
      if response.is_a?(Net::HTTPSuccess)
        File.binwrite(dest_file, response.body)
        puts "  saved #{stat_key}.avif"
      else
        puts "  FAILED #{stat_key}: #{response.code}"
      end
    end

    puts "Done. Stat icons saved to public/images/forte/stats/"
  end

  desc "Download skill icons from wutheringlab into public/images/forte/skills/[slug]/"
  task download_skill_icons: :environment do
    Resonator.find_each do |resonator|
      slug = resonator.name.downcase.gsub(/['"#&]/, "").strip.gsub(/\s+/, "-")
      dest = Rails.root.join("public/images/forte/skills/#{slug}")
      FileUtils.mkdir_p(dest)

      overrides = SKILL_LABEL_OVERRIDES_RAKE[slug] || {}
      name_segment = resonator.name.gsub(/['"#&]/, "").strip.gsub(/\s+/, "-")

      SKILL_LABELS_RAKE.each do |skill_key, default_label|
        actual_label = overrides[skill_key] || default_label
        url          = "#{WUTHERINGLAB_BASE}/#{name_segment}-#{actual_label}.webp"
        dest_file    = dest.join("#{actual_label.downcase}.webp")

        if dest_file.exist?
          puts "  skip #{slug}/#{actual_label.downcase}.webp"
          next
        end

        puts "  downloading #{slug}/#{actual_label}..."
        response = Net::HTTP.get_response(URI(url))
        if response.is_a?(Net::HTTPSuccess)
          File.binwrite(dest_file, response.body)
          puts "  saved #{slug}/#{actual_label.downcase}.webp"
        else
          puts "  FAILED #{slug}/#{actual_label}: #{response.code}"
        end
      end
    end

    puts "Done. Skill icons saved to public/images/forte/skills/"
  end
end
