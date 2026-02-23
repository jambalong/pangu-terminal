module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_key!

      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActionController::ParameterMissing, with: :handle_bad_request

      private

      def authenticate_api_key!
        authenticate_with_http_token do |token, _options|
          api_key = ApiKey.find_by(token: token)
          @current_user = api_key&.user
        end

        handle_unauthorized unless @current_user
      end

      def handle_unauthorized
        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def handle_not_found
        render json: { error: "Record not found" }, status: :not_found
      end

      def handle_bad_request(e)
        render json: { error: e.message }, status: :bad_request
      end
    end
  end
end
