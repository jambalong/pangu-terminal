class PlansController < ApplicationController
  before_action :set_planner_id

  def index
    @plans = Plan.where(planner_id: @planner_id)
  end

  def new
    @step = (params[:step] || 1).to_i
    @plan_type = params[:plan_type] || params.dig(:plan, :plan_type)
    @items = []
    @item = nil

    case @step
    when 2
      @items = (@plan_type == "Resonator" ? Resonator : Weapon).order(:name)
    when 3
      item_id = params[:item_id] || params.dig(:plan, :item_id)
      @item = (@plan_type == "Resonator" ? Resonator : Weapon).find(item_id)
    end
    # Rails automatically renders new.html.erb, which uses the @variables above
  end

  def create
    p = plan_params
    plan_type = p[:plan_type]
    item = (plan_type == "Resonator" ? Resonator : Weapon).find_by!(id: p[:item_id])

    begin
      resonator_data = plan_type == "Resonator" ? build_resonator_data(p) : {}

      planner = if plan_type == "Resonator"
        ResonatorAscensionPlanner.new(
          resonator: item,
          **base_params(p),
          **resonator_data
        )
      else
        WeaponAscensionPlanner.new(
          weapon: item,
          **base_params(p)
        )
      end

      output_data = planner.call
      material_names = Material.where(id: output_data.keys).pluck(:id, :name).to_h
      final_output = output_data.transform_keys { |id| material_names[id.to_i] || "N/A" }

      @plan = Plan.new(
        planner_id: @planner_id,
        plan_type: plan_type,
        plan_data: {
          input: { name: item.name, **base_params(p) }.merge(resonator_data),
          output: final_output
        }
      )

      if @plan.save
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to plans_path }
        end
      end

    rescue ResonatorAscensionPlanner::ValidationError, WeaponAscensionPlanner::ValidationError => e
      @errors = e.message.split("|")
      render_form_with_errors
    rescue ActiveRecord::RecordNotFound
      @errors = [ "The selected #{plan_type} could not be found." ]
      render_form_with_errors
    rescue StandardError => e
      @errors = [ "An unexpected error occurred. Please try again." ]
      render_form_with_errors
    end
  end

  def confirm_delete
    @plan = Plan.find(params[:id])
  end

  def destroy
    @plan = Plan.find(params[:id])
    @plan.destroy

    respond_to do |format|
      format.turbo_stream # This will look for destroy.turbo_stream.erb
      format.html { redirect_to plans_path, notice: "Plan deleted." }
    end
  end

  private
  def set_planner_id
    cookies.permanent[:planner_id] ||= SecureRandom.uuid
    @planner_id = cookies.permanent[:planner_id]
  end

  def render_form_with_errors
    plan_type = params[:plan_type]
    item_id = params[:item_id]
    item = (plan_type == "Resonator" ? Resonator : Weapon).find(item_id)

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("plan-form-frame",
               partial: "plans/form",
               locals: {
                 errors: @errors,
                 item: item,
                 plan_type: plan_type
               })
      }
    end
  end

  def plan_params
    core = [ :plan_type, :item_id, :current_level, :target_level, :current_ascension_rank, :target_ascension_rank ]

    # Skill fields
    skills = [
      :basic_attack_current, :basic_attack_target,
      :resonance_skill_current, :resonance_skill_target,
      :forte_circuit_current, :forte_circuit_target,
      :resonance_liberation_current, :resonance_liberation_target,
      :intro_skill_current, :intro_skill_target
    ]

    # Node fields (Booleans)
    nodes = [
      :basic_attack_node_1, :basic_attack_node_2,
      :resonance_skill_node_1, :resonance_skill_node_2,
      :forte_circuit_node_1, :forte_circuit_node_2,
      :resonance_liberation_node_1, :resonance_liberation_node_2,
      :intro_skill_node_1, :intro_skill_node_2
    ]

    params.require(:plan).permit(core + skills + nodes)
  end

  def base_params(p)
    {
      current_level: p[:current_level].to_i,
      target_level: p[:target_level].to_i,
      current_ascension_rank: p[:current_ascension_rank].to_i,
      target_ascension_rank: p[:target_ascension_rank].to_i
    }
  end

  def build_resonator_data(p)
    {
      current_skill_levels: map_skills(p, :current),
      target_skill_levels: map_skills(p, :target),
      forte_node_upgrades: map_nodes(p)
    }
  end

  def map_skills(p, suffix)
    {
      basic_attack: p["basic_attack_#{suffix}"].to_i,
      resonance_skill: p["resonance_skill_#{suffix}"].to_i,
      forte_circuit: p["forte_circuit_#{suffix}"].to_i,
      resonance_liberation: p["resonance_liberation_#{suffix}"].to_i,
      intro_skill: p["intro_skill_#{suffix}"].to_i
    }
  end

  def map_nodes(p)
    {
      "Basic Attack Node 1" => p[:basic_attack_node_1].to_i,
      "Basic Attack Node 2" => p[:basic_attack_node_2].to_i,
      "Resonance Skill Node 1" => p[:resonance_skill_node_1].to_i,
      "Resonance Skill Node 2" => p[:resonance_skill_node_2].to_i,
      "Forte Circuit Node 1" => p[:forte_circuit_node_1].to_i,
      "Forte Circuit Node 2" => p[:forte_circuit_node_2].to_i,
      "Resonance Liberation Node 1" => p[:resonance_liberation_node_1].to_i,
      "Resonance Liberation Node 2" => p[:resonance_liberation_node_2].to_i,
      "Intro Skill Node 1" => p[:intro_skill_node_1].to_i,
      "Intro Skill Node 2" => p[:intro_skill_node_2].to_i
    }
  end
end
