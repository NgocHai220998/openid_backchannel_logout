# frozen_string_literal: true

module OpenidBackchannelLogout
  module Error
    class EncodeError < StandardError; end
    class DecodeError < StandardError; end
    class MissingLogoutTokenError < StandardError; end
    class InvalidLogoutTokenError < DecodeError; end

    class MissingRequiredClaimError < DecodeError
      def initialize(claim)
        super("Missing #{claim} claim")
      end
    end

    class MissingSubOrSidClaimError < DecodeError; end
    class InvalidAlgorithmError < DecodeError; end
    class InvalidIatError < DecodeError; end

    class InvalidIssuerError < DecodeError
      def initialize(expected_issuer, actual_issuer)
        super("Invalid iss claim. Expected: #{expected_issuer}, but received: #{actual_issuer || '<none>'}")
      end
    end

    class InvalidAudError < DecodeError
      def initialize(expected_audience, actual_audience)
        super("Invalid aud claim. Expected: #{expected_audience}, but received: #{actual_audience || '<none>'}")
      end
    end

    class InvalidEventsError < DecodeError; end
    class TokenExpiredError < DecodeError; end

    class InvalidNonceError < DecodeError
      def message
        'Nonce claim is not allowed in Logout Token'
      end
    end

    class IssuerNotConfiguredError < StandardError
      def message
        'Issuer must be set in OpenidBackchannelLogout configuration'
      end
    end

    class AudienceNotConfiguredError < StandardError
      def message
        'Audience (Client ID) must be set in OpenidBackchannelLogout configuration'
      end
    end

    class NoBlockProvidedError < StandardError; end
  end
end
