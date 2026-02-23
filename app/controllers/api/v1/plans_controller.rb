module Api
  module V1
    class PlansController < Api::V1::BaseController
      def index
        plans = @current_user.plans.includes(:subject)
        materials_summary = Plan.fetch_materials_summary(plans)
        materials_lookup = Material.index_by_ids(materials_summary.keys)

        render json: plans.map { |plan| PlanSerializer.new(plan, materials_lookup).to_h }
      end
    end
  end
end
