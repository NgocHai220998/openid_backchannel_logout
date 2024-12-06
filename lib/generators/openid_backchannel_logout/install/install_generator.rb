# frozen_string_literal: true

require 'rails/generators'

module OpenidBackchannelLogout
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __dir__)

      def create_initializer
        copy_file 'initializer.rb', 'config/initializers/openid_backchannel_logout.rb'
      end

      def create_controller
        template 'backchannel_logouts_controller.rb', 'app/controllers/api/internal/backchannel_logouts_controller.rb'
      end

      def create_routes
        routes_file = File.join('config', 'routes.rb')
        route_to_add = "resource :backchannel_logout, only: :create\n"

        if File.readlines(routes_file).grep(/resource :backchannel_logout/).any?
          say_status('skipped', 'Routes for backchannel_logout already exist, skipping.', :yellow)
        else
          content = File.read(routes_file)

          if content.match?(/namespace :internal(,.*)? do/)
            # Inject into the existing `namespace :internal` block
            inject_into_file routes_file, "      #{route_to_add}", after: /namespace :internal(,.*)? do\n/
            say_status('added', 'Route added to existing namespace :internal.', :green)
          elsif content.match?(/namespace :api(,.*)? do/)
            inject_into_file routes_file, <<-RUBY, after: /namespace :api(,.*)? do\n/
    namespace :internal do
      #{route_to_add.strip}
    end
            RUBY
            say_status('added', 'Namespace :internal created and route added.', :green)
          else
            inject_into_file routes_file, <<-RUBY, after: /Rails.application.routes.draw(,.*)? do\n/
  namespace :api, defaults: { format: 'json' } do
    namespace :internal do
      #{route_to_add.strip}
    end
  end
            RUBY
            say_status('added', 'Namespace :api and :internal created, and route added.', :green)
          end
        end
      end
    end
  end
end
