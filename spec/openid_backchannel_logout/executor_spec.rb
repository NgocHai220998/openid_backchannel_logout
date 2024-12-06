require 'spec_helper'
require 'openid_backchannel_logout/executor'

RSpec.describe OpenidBackchannelLogout::Executor do
  let(:logout_token) { 'valid.jwt.token' }
  let(:request) { double(params: { logout_token: }) }
  let(:executor) { described_class.new }
  let(:expected_issuer) { 'https://idp.example.com/' }
  let(:expected_audience) { 'my-client-id' }
  let(:discovery_url) { "#{expected_issuer}/.well-known/openid-configuration" }
  let(:discovery_response) { { 'jwks_uri' => 'https://idp.example.com/oauth/discovery/keys' }.to_json }
  let(:validator_instance) { instance_double(OpenidBackchannelLogout::TokenValidator, valid!: true, decoded_token: [decoded_payload]) }
  let(:decoded_payload) { { 'sub' => 'test-user', 'sid' => 'test-session' } }
  
  before do
    OpenidBackchannelLogout.configure do |config|
      config.issuer = expected_issuer
      config.audience = expected_audience
    end

    allow(Net::HTTP).to receive(:get).with(URI(discovery_url)).and_return(discovery_response)
    allow(OpenidBackchannelLogout::TokenValidator).to receive(:new).and_return(validator_instance)
  end

  describe '#call' do
    context 'when the logout_token is missing' do
      let(:request) { double(params: {}) }

      it 'raises MissingLogoutTokenError' do
        expect { executor.call(request) }.to raise_error(OpenidBackchannelLogout::Error::MissingLogoutTokenError)
      end
    end

    context 'when the discovery document fetch fails' do
      before do
        allow(Net::HTTP).to receive(:get).and_raise(StandardError, 'network error')
      end

      it 'raises DecodeError with a message' do
        expect { executor.call(request) }.to raise_error(OpenidBackchannelLogout::Error::DecodeError, 'Failed to fetch JWKS URI: network error')
      end
    end

    context 'when the discovery document is invalid' do
      before do
        allow(Net::HTTP).to receive(:get).and_return('invalid json')
      end

      it 'raises DecodeError due to JSON parse failure' do
        expect { executor.call(request) }.to raise_error(OpenidBackchannelLogout::Error::DecodeError, 'Failed to parse OpenID Connect discovery document')
      end
    end

    context 'when the JWKS URI is missing in the discovery document' do
      before do
        allow(Net::HTTP).to receive(:get).and_return({}.to_json)
      end

      it 'raises DecodeError' do
        expect { executor.call(request) }.to raise_error(OpenidBackchannelLogout::Error::DecodeError, 'Failed to fetch JWKS URI: JWKS URI not found in discovery document')
      end
    end

    context 'when no block is provided' do
      it 'raises NoBlockProvidedError' do
        expect { executor.call(request) }.to raise_error(OpenidBackchannelLogout::Error::NoBlockProvidedError, 'No block provided for handling sub and sid')
      end
    end

    context 'when the token is valid' do
      it 'yields sub and sid to the provided block' do
        expect do |block|
          executor.call(request, &block)
        end.to yield_with_args('test-user', 'test-session')
      end

      it 'calls the TokenValidator with correct arguments' do
        executor.call(request) {}
        expect(OpenidBackchannelLogout::TokenValidator).to have_received(:new).with(
          logout_token,
          'https://idp.example.com/oauth/discovery/keys',
          expected_issuer,
          expected_audience
        )
      end
    end
  end
end
