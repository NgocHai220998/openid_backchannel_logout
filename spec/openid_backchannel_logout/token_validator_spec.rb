# frozen_string_literal: true

require 'spec_helper'
require 'openid_backchannel_logout/token_validator'

RSpec.describe OpenidBackchannelLogout::TokenValidator do
  let(:jwt_token) { 'valid.jwt.token' }
  let(:jwks_uri) { 'https://idp.example.com/oauth/discovery/keys' }
  let(:expected_issuer) { 'https://idp.example.com' }
  let(:expected_audience) { 'my-client-id' }
  let(:decoded_payload) do
    {
      'iss' => expected_issuer,
      'aud' => expected_audience,
      'iat' => Time.now.to_i,
      'exp' => Time.now.to_i + 3600,
      'events' => { 'http://schemas.openid.net/event/backchannel-logout' => {} },
      'sub' => 'user123'
    }
  end
  let(:validator) { described_class.new(jwt_token, jwks_uri, expected_issuer, expected_audience) }

  before do
    allow(Net::HTTP).to receive(:get).and_return({
      keys: [
        { kty: 'RSA', kid: 'key-id', use: 'sig', n: 'base64encodedmodulus', e: 'AQAB' }
      ]
    }.to_json)

    allow(JWT).to receive(:decode).with(jwt_token, nil, false).and_return([{ 'alg' => 'RS256' }])
    allow(JWT).to receive(:decode).with(jwt_token, nil, true,
                                        algorithms: ['RS256'],
                                        jwks: anything).and_return([decoded_payload])
  end

  describe '#valid!' do
    context 'when the token is valid' do
      it 'does not raise any error' do
        expect { validator.valid! }.not_to raise_error
      end
    end

    context 'when the token has an invalid algorithm' do
      before do
        allow(JWT).to receive(:decode).with(jwt_token, nil, false).and_return([{ 'alg' => 'none' }])
      end

      it 'raises an InvalidAlgorithmError' do
        expect { validator.valid! }.to raise_error(OpenidBackchannelLogout::Error::InvalidAlgorithmError)
      end
    end

    context 'when the token has an invalid issuer' do
      before do
        decoded_payload['iss'] = 'https://wrong-issuer.com'
      end

      it 'raises an InvalidIssuerError' do
        expect { validator.valid! }.to raise_error(OpenidBackchannelLogout::Error::InvalidIssuerError)
      end
    end

    context 'when the token has an invalid audience' do
      before do
        decoded_payload['aud'] = 'wrong-client-id'
      end

      it 'raises an InvalidAudError' do
        expect { validator.valid! }.to raise_error(OpenidBackchannelLogout::Error::InvalidAudError)
      end
    end

    context 'when the token is missing required claims' do
      it 'raises MissingRequiredClaimError for iat' do
        decoded_payload.delete('iat')
        expect do
          validator.valid!
        end.to raise_error(OpenidBackchannelLogout::Error::MissingRequiredClaimError, 'Missing iat claim')
      end

      it 'raises MissingRequiredClaimError for exp' do
        decoded_payload.delete('exp')
        expect do
          validator.valid!
        end.to raise_error(OpenidBackchannelLogout::Error::MissingRequiredClaimError, 'Missing exp claim')
      end

      it 'raises MissingRequiredClaimError for events' do
        decoded_payload.delete('events')
        expect do
          validator.valid!
        end.to raise_error(OpenidBackchannelLogout::Error::MissingRequiredClaimError, 'Missing events claim')
      end
    end

    context 'when the token has an invalid events claim' do
      before do
        decoded_payload['events'] = { 'invalid-event-key' => {} }
      end

      it 'raises InvalidEventsError' do
        expect { validator.valid! }.to raise_error(OpenidBackchannelLogout::Error::InvalidEventsError)
      end
    end

    context 'when the token is missing sub and sid' do
      before do
        decoded_payload.delete('sub')
        decoded_payload.delete('sid')
      end

      it 'raises MissingSubOrSidClaimError' do
        expect { validator.valid! }.to raise_error(OpenidBackchannelLogout::Error::MissingSubOrSidClaimError)
      end
    end

    context 'when the token contains a nonce claim' do
      before do
        decoded_payload['nonce'] = 'some-nonce'
      end

      it 'raises InvalidNonceError' do
        expect { validator.valid! }.to raise_error(OpenidBackchannelLogout::Error::InvalidNonceError)
      end
    end

    context 'when the token is expired' do
      before do
        decoded_payload['exp'] = Time.now.to_i - 3600
      end

      it 'raises TokenExpiredError' do
        expect { validator.valid! }.to raise_error(OpenidBackchannelLogout::Error::TokenExpiredError)
      end
    end
  end
end
