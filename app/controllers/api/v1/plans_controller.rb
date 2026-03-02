module Api
  module V1
    class PlansController < Api::V1::BaseController
      def index
        plans = @current_user.plans.includes(:subject)
        materials_summary = Plan.fetch_materials_summary(plans)
        materials_lookup = Material.index_by_ids(materials_summary.keys)

        render json: plans.map { |plan| PlanSerializer.new(plan, materials_lookup).to_h }
      end

      def create
        form = PlanForm.new(plan_params)
        subject = form.subject_type&.safe_constantize&.find_by(id: form.subject_id)

        return render json: { error: "Subject not found" }, status: :not_found if subject.nil?

        plan = form.save(@current_user, nil)

        if plan
          materials_lookup = Material.index_by_ids(plan.plan_data.dig("output").keys.map(&:to_i))
          render json: PlanSerializer.new(plan, materials_lookup).to_h, status: :created
        else
          render json: { errors: form.errors.full_messages }, status: unprocessable_entity
        end

      rescue ResonatorAscensionPlanner::ValidationError,
          WeaponAscensionPlanner::ValidationError => e
        render json: { errors: e.message.split("|") }, status: :unprocessable_entity
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def plan_params
        params.permit(
          :subject_type, :subject_id,
          :current_level, :target_level,
          :current_ascension_rank, :target_ascension_rank,
          :basic_attack_current, :basic_attack_target,
          :resonance_skill_current, :resonance_skill_target,
          :forte_circuit_current, :forte_circuit_target,
          :resonance_liberation_current, :resonance_liberation_target,
          :intro_skill_current, :intro_skill_target,
          :basic_attack_node_1, :basic_attack_node_2,
          :resonance_skill_node_1, :resonance_skill_node_2,
          :forte_circuit_node_1, :forte_circuit_node_2,
          :resonance_liberation_node_1, :resonance_liberation_node_2,
          :intro_skill_node_1, :intro_skill_node_2
        )
      end
    end
  end
end
