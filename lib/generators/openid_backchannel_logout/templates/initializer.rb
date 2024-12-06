# frozen_string_literal: true

OpenidBackchannelLogout.configure do |config|
  config.issuer = ENV.fetch('OIDC_ISSUER', '') # OpenID Provider
  config.audience = ENV.fetch('OIDC_CLIENT_ID', '') # Your Client ID
end
