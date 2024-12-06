# frozen_string_literal: true

require 'openid_backchannel_logout/configuration'
require 'openid_backchannel_logout/executor'

module OpenidBackchannelLogout
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)

      configuration.validate!
    end
  end
end
