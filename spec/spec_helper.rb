# frozen_string_literal: true

require 'active_support/all'
require 'openid_backchannel_logout'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
