# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenidBackchannelLogout::Configuration do
  let(:config) { OpenidBackchannelLogout.configuration }

  before do
    OpenidBackchannelLogout.configure do |c|
      c.issuer = 'https://idp.example.com'
      c.audience = 'my-client-id'
    end
  end

  it 'sets the issuer correctly' do
    expect(config.issuer).to eq('https://idp.example.com')
  end

  it 'sets the audience correctly' do
    expect(config.audience).to eq('my-client-id')
  end

  it 'raises an error when issuer is not set' do
    expect do
      OpenidBackchannelLogout.configure do |c|
        c.issuer = nil
      end
    end.to raise_error(StandardError)
  end

  it 'raises an error when audience is not set' do
    expect do
      OpenidBackchannelLogout.configure do |c|
        c.audience = nil
      end
    end.to raise_error(StandardError)
  end
end
