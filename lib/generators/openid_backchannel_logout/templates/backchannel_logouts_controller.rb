# frozen_string_literal: true

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
