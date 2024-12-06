# frozen_string_literal: true

require_relative 'error'

module OpenidBackchannelLogout
  class Configuration
    attr_accessor :issuer, :audience

    def validate!
      raise Error::IssuerNotConfiguredError unless issuer.present?
      raise Error::AudienceNotConfiguredError unless audience.present?
    end
  end
end
