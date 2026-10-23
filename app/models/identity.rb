# A sign-in method linked to a User: one row per (provider, uid) pair.
class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, inclusion: { in: ->(_) { OauthProviders.names.map(&:to_s) } }
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :provider, uniqueness: { scope: :user_id }

  def provider_label = OauthProviders.label(provider)
end
