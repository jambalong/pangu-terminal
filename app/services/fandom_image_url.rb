require "digest/md5"

# Builds the static image URL for a file on a Fandom (MediaWiki) wiki.
#
# MediaWiki stores uploads under /<h1>/<h1h2>/<File>, where h is the MD5 hex
# digest of the raw file name, so a URL can be derived from a record name:
#
#   FandomImageUrl.call(name: "Azure Oath", prefix: "Weapon_", base: BASE)
#   # => ".../images/2/20/Weapon_Azure_Oath.png/revision/latest"
#
# `wiki_names` maps a record name to the wiki's file stem when they differ
# (e.g. every Rover shares "Resonator_Rover.png").
class FandomImageUrl < ApplicationService
  def initialize(name:, prefix:, base:, ext: "png", wiki_names: {})
    @name = name
    @prefix = prefix
    @base = base.chomp("/")
    @ext = ext
    @wiki_names = wiki_names
  end

  def call
    digest = Digest::MD5.hexdigest(file_name)
    "#{@base}/#{digest[0]}/#{digest[0, 2]}/#{encoded_file_name}/revision/latest"
  end

  private

  def file_name
    stem = @wiki_names.fetch(@name, @name).delete(":").strip.tr(" ", "_")
    "#{@prefix}#{stem}.#{@ext}"
  end

  # The hash uses the raw name; only the path segment is percent-encoded
  # (apostrophes stay literal, as on the wiki's own URLs).
  def encoded_file_name
    ERB::Util.url_encode(file_name).gsub("%27", "'")
  end
end
