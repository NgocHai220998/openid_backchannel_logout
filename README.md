# OpenID Backchannel Logout

The OpenidBackchannelLogout gem offers an easy way to implement OpenID Connect Back-Channel Logout functionality in your **Ruby on Rails** application. It is designed to comply to the [OpenID Connect Back-Channel Logout](https://openid.net/specs/openid-connect-backchannel-1_0.html) specification for client-side operations.

Gem: https://rubygems.org/gems/openid_backchannel_logout

If you notice any issues, feel free to let me know (^-^)

## Features

- Validates Logout Tokens according to the OpenID Connect specification.
- Handles back-channel logout requests with minimal setup.
- Rails generator for auto-creating controllers, routes, and initializers.

## Installation

Add the gem to your Gemfile:
```ruby
gem 'openid_backchannel_logout'
```

Then install it:
```ruby
bundle install
```

Basic Usage:
```ruby
# in your controller

OpenidBackchannelLogout::Executor.new.call(request) do |sub, sid|
  Rails.logger.info("Logging out user with sub: #{sub}, sid: #{sid}")
  # TODO: Implement the logic to logout the user
end
```

Or you can use ↓

## Generators

**1. Setup Configuration**

Run the gem's generator to set up the configuration, controller, and routes:
```bash
rails generate openid_backchannel_logout:install
```
***This will*:**

**Create an initializer at `config/initializers/openid_backchannel_logout.rb`**:
```ruby
OpenidBackchannelLogout.configure do |config|
  config.issuer = ENV.fetch('OIDC_ISSUER', '') # OpenID Provider
  config.audience = ENV.fetch('OIDC_CLIENT_ID', '') # Your Client ID
end
```
Set the required environment variables in your application:
- `OIDC_ISSUER`: The OpenID Provider's URL (e.g., https://idp.example.com).
- `OIDC_CLIENT_ID`: The Client ID registered with the OpenID Provider.

**Create a controller at `app/controllers/api/internal/backchannel_logouts_controller.rb`**:
```ruby
module Api
  module Internal
    class BackchannelLogoutsController < ActionController::API
      def create
        OpenidBackchannelLogout::Executor.new.call(request) do |sub, sid|
          Rails.logger.info("Logging out user with sub: #{sub}, sid: #{sid}")
          # TODO: Implement the logic to logout the user
        end

        render plain: 'Logout successful', status: :ok
      rescue StandardError => e
        Rails.logger.error("Backchannel logout error: #{e.message}")
        render plain: e.message, status: :bad_request
      end
    end
  end
end
```
You can customize the create action to define how your application should log out users based on sub (subject identifier) or sid (session ID).

**Add a route to `config/routes.rb`**:
```ruby
namespace :api, defaults: { format: 'json' } do
  namespace :internal do
    resource :backchannel_logout, only: :create
  end
end
```

***Note***: You can customize it in any way you like.

## Testing

```bash
bundle exec rspec
```
If you are integrating the gem into your application, you can also test the generated routes and controller by simulating logout requests.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
