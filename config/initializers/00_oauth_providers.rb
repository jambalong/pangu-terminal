# OAuth providers are configured from ENV (not encrypted credentials) so the app
# boots and CI passes with none set. A provider is "enabled" (shows a sign-in
# button, accepts requests) only when both its variables are present.
module OauthProviders
  PROVIDERS = {
    google_oauth2: { label: "Google", id: "GOOGLE_CLIENT_ID", secret: "GOOGLE_CLIENT_SECRET", scope: "openid,profile" },
    discord: { label: "Discord", id: "DISCORD_CLIENT_ID", secret: "DISCORD_CLIENT_SECRET", scope: "identify" }
  }.freeze

  def self.names = PROVIDERS.keys

  def self.label(provider) = PROVIDERS.fetch(provider.to_sym)[:label]

  def self.configured?(provider)
    config = PROVIDERS.fetch(provider.to_sym)
    ENV[config[:id]].present? && ENV[config[:secret]].present?
  end

  def self.enabled = names.select { |provider| configured?(provider) }

  def self.any? = enabled.any?
end
