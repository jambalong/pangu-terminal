# Content security policy. Scripts must be same-origin or carry the per-request
# nonce (the importmap tags get it automatically). Styles allow 'unsafe-inline'
# because views use inline style attributes; fonts come from Google Fonts.
# form-action is left unset on purpose: browsers apply it to redirects after a
# form post, which would block the OAuth hand-off to Google and Discord.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.script_src      :self
    policy.style_src       :self, :unsafe_inline, "https://fonts.googleapis.com"
    policy.font_src        :self, :data, "https://fonts.gstatic.com"
    policy.img_src         :self, :data
    policy.connect_src     :self
    policy.object_src      :none
    policy.base_uri        :self
    policy.frame_ancestors :none
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[ script-src ]
end
