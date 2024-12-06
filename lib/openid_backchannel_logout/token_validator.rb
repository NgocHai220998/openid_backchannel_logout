# frozen_string_literal: true

require 'jwt'
require 'net/http'
require 'json'

module OpenidBackchannelLogout
  class TokenValidator
    attr_reader :decoded_token

    EVENT_KEY = 'http://schemas.openid.net/event/backchannel-logout'

    def initialize(jwt_token, jwks_uri, expected_issuer, expected_audience, options = {})
      @jwt_token = jwt_token
      @jwks_uri = jwks_uri
      @expected_issuer = expected_issuer
      @expected_audience = expected_audience

      # TODO: Implement validation for claims that are not required by the spec
      # https://openid.net/specs/openid-connect-backchannel-1_0.html
      @options = options
    end

    def valid!
      decode_and_validate_token
      validate_claims
    end

    private

    def decode_and_validate_token
      header = JWT.decode(@jwt_token, nil, false).last
      raise Error::InvalidAlgorithmError if header['alg'] == 'none'

      @decoded_token = JWT.decode(@jwt_token, nil, true,
                                  algorithms: [header['alg']],
                                  jwks: jwks_keys)
    end

    def jwks_keys
      @jwks_keys ||= begin
        response = Net::HTTP.get(URI(@jwks_uri))
        JSON.parse(response)['keys']
      end
    end

    def validate_claims
      payload = @decoded_token.first

      validate_required_claims(payload)
    end

    def validate_required_claims(payload)
      validate_iss(payload['iss'])
      validate_aud(payload['aud'])
      validate_timestamps(payload['iat'], payload['exp'])
      validate_events(payload['events'])
      validate_subject_or_session(payload)
      validate_no_nonce(payload)
    end

    def validate_iss(iss)
      raise Error::InvalidIssuerError.new(@expected_issuer, iss) unless iss == @expected_issuer
    end

    def validate_aud(aud)
      return if Array(aud).include?(@expected_audience)

      raise Error::InvalidAudError.new(@expected_audience, Array(aud))
    end

    def validate_timestamps(iat, exp)
      raise Error::MissingRequiredClaimError, :iat unless iat
      raise Error::MissingRequiredClaimError, :exp unless exp

      raise Error::TokenExpiredError if Time.now.to_i > exp
    end

    def validate_events(events)
      raise Error::MissingRequiredClaimError, :events unless events
      raise Error::InvalidEventsError unless events.key?(EVENT_KEY)
    end

    def validate_subject_or_session(payload)
      raise Error::MissingSubOrSidClaimError unless payload['sub'] || payload['sid']
    end

    def validate_no_nonce(payload)
      raise Error::InvalidNonceError if payload.key?('nonce')
    end
  end
end
