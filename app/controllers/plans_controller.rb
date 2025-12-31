class PlansController < ApplicationController
  before_action :set_guest_token
  before_action :set_plan, only: [ :destroy, :confirm_delete ]
  before_action :authorize_owner!, only: [ :destroy, :confirm_delete ]

  def index
    if user_signed_in?
      @plans = current_user.plans
    else
      @plans = Plan.where(guest_token: @guest_token, user_id: nil)
    end
  end

  def new
    @step = (params[:step] || 1).to_i
    @plan_type = params[:plan_type] || params.dig(:plan, :plan_type)
    @subjects = []
    @subject = nil

    case @step
    when 2
      @subjects = (@plan_type == "Resonator" ? Resonator : Weapon).order(:name)
    when 3
      subject_id = params[:subject_id] || params.dig(:plan, :subject_id)
      @subject = (@plan_type == "Resonator" ? Resonator : Weapon).find(subject_id)
    end
    # Rails automatically renders new.html.erb, which uses the @variables above
  end

  def create
    p = plan_params
    plan_type = p[:plan_type]
    subject = (plan_type == "Resonator" ? Resonator : Weapon).find_by!(id: p[:subject_id])

    @errors = []

    existing = if user_signed_in?
      current_user.plans.find_by("plan_data->'input'->>'subject_id' = ?", subject.id.to_s)
    else
      Plan.where(user_id: nil, guest_token: @guest_token)
          .find_by("plan_data->'input'->>'subject_id' = ?", subject.id.to_s)
    end

    if existing
      @errors = [ "You already have a plan for #{subject.name}." ]
      return render_form_with_errors
    end

    begin
      resonator_data = plan_type == "Resonator" ? build_resonator_data(p) : {}

      planner = if plan_type == "Resonator"
        ResonatorAscensionPlanner.new(
          resonator: subject,
          **base_params(p),
          **resonator_data
        )
      else
        WeaponAscensionPlanner.new(
          weapon: subject,
          **base_params(p)
        )
      end

      output_data = planner.call
      material_names = Material.where(id: output_data.keys).pluck(:id, :name).to_h
      final_output = output_data.transform_keys { |id| material_names[id.to_i] || "N/A" }

      @plan = Plan.new(
        plan_type: plan_type,
        guest_token: @guest_token,
        user: current_user,
        plan_data: {
          input: { subject_name: subject.name, subject_id: subject.id, **base_params(p) }.merge(resonator_data),
          output: final_output
        }
      )

      if @plan.save
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to plans_path }
        end
      else
        @errors = @plan.errors.full_messages
        render_form_with_errors
      end

    rescue ResonatorAscensionPlanner::ValidationError, WeaponAscensionPlanner::ValidationError => e
      @errors = e.message.split("|")
      render_form_with_errors
    rescue ActiveRecord::RecordNotFound
      @errors = [ "The selected #{plan_type} could not be found." ]
      render_form_with_errors
    rescue StandardError => e
      @errors = [ "An error occurred: #{e.message}" ]
      render_form_with_errors
    end
  end

  def confirm_delete
  end

  def destroy
    @plan.destroy

    respond_to do |format|
      format.turbo_stream # This will look for destroy.turbo_stream.erb
      format.html { redirect_to plans_path, notice: "Plan deleted." }
    end
  end

  private

  def set_guest_token
    if cookies.permanent[:guest_token].blank?
      cookies.permanent[:guest_token] = SecureRandom.uuid
    end

    @guest_token = cookies.permanent[:guest_token]
  end

  def set_plan
    @plan = Plan.find(params[:id])
  end

  def authorize_owner!
    is_user_owner = user_signed_in? && @plan.user_id == current_user.id
    is_guest_owner  = @plan.user_id.nil? && @plan.guest_token == @guest_token

    unless is_user_owner || is_guest_owner
      redirect_to plans_path, alert: "You don't have permission to modify this plan."
    end
  end

  def render_form_with_errors
    plan_type = params[:plan_type] || params.dig(:plan, :plan_type)
    subject_id = params[:subject_id] || params.dig(:plan, :subject_id)
    subject = (plan_type == "Resonator" ? Resonator : Weapon).find(subject_id)

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("plan-form-frame",
               partial: "plans/form",
               locals: {
                 errors: @errors&.uniq,
                 subject: subject,
                 plan_type: plan_type
               })
      }
    end
  end

  def plan_params
    core = [ :plan_type, :subject_id, :current_level, :target_level, :current_ascension_rank, :target_ascension_rank ]

    # Skill fields
    skills = [
      :basic_attack_current, :basic_attack_target,
      :resonance_skill_current, :resonance_skill_target,
      :forte_circuit_current, :forte_circuit_target,
      :resonance_liberation_current, :resonance_liberation_target,
      :intro_skill_current, :intro_skill_target
    ]

    # Node fields (0 or 1)
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
