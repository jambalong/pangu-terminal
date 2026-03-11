module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_key!
      skip_before_action :authenticate_api_key!, only: :handle_not_found

      rescue_from StandardError, with: :handle_server_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActionController::ParameterMissing, with: :handle_bad_request

      def handle_not_found
        render json: { error: "Record not found" }, status: :not_found
      end

      private

      def authenticate_api_key!
        authenticate_with_http_token do |token, _options|
          api_key = ApiKey.find_by(token: Digest::SHA256.hexdigest(token))
          api_key&.touch(:last_used_at)
          @current_user = api_key&.user
        end

        handle_unauthorized unless @current_user
      end

      def handle_unauthorized
        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def handle_bad_request(e)
        render json: { error: e.message }, status: :bad_request
      end

      def handle_server_error(e)
        Rails.logger.error(e.message)
        render json: { error: "Internal Server Error" }, status: :internal_server_error
      end
    end
  end
end
