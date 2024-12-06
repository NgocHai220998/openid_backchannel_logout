# frozen_string_literal: true

require_relative 'error'
require_relative 'token_validator'

module OpenidBackchannelLogout
  class Executor
    def initialize
      @expected_issuer = OpenidBackchannelLogout.configuration.issuer
      @expected_audience = OpenidBackchannelLogout.configuration.audience
    end

    def call(request)
      logout_token = extract_token(request)
      raise Error::MissingLogoutTokenError unless logout_token

      jwks_uri = fetch_jwks_uri

      validator = TokenValidator.new(
        logout_token,
        jwks_uri,
        @expected_issuer,
        @expected_audience
      )

      validator.valid!

      payload = validator.decoded_token.first
      sub = payload['sub']
      sid = payload['sid']

      raise Error::NoBlockProvidedError, 'No block provided for handling sub and sid' unless block_given?

      yield(sub, sid)
    end

    private

    def extract_token(request)
      request.params[:logout_token]
    end

    def fetch_jwks_uri
      discovery_url = "#{@expected_issuer}/.well-known/openid-configuration"
      response = Net::HTTP.get(URI(discovery_url))
      discovery_data = JSON.parse(response)

      discovery_data['jwks_uri'] || raise(Error::DecodeError, 'JWKS URI not found in discovery document')
    rescue JSON::ParserError
      raise Error::DecodeError, 'Failed to parse OpenID Connect discovery document'
    rescue StandardError => e
      raise Error::DecodeError, "Failed to fetch JWKS URI: #{e.message}"
    end
  end
end
