module Api
  module V1
    class ProfileController < Api::V1::BaseController
      def update
        sol3_phase = params[:sol3_phase].to_i

        unless DropRate::SOL3_PHASES.cover?(sol3_phase)
          return render json: { error: "sol3_phase must be an integer between #{DropRate::SOL3_PHASES.first} and #{DropRate::SOL3_PHASES.last}" }, status: :unprocessable_entity
        end

        if @current_user.update(sol3_phase: sol3_phase)
          render json: { sol3_phase: @current_user.sol3_phase }, status: :ok
        else
          render json: { error: @current_user.errors.full_messages.first }, status: :unprocessable_entity
        end
      end
    end
  end
end
