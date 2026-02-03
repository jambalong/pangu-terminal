class PlansController < ApplicationController
  include PlanLoading

  before_action :set_guest_token
  before_action :set_plan, only: [ :edit, :update, :destroy, :confirm_delete ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy, :confirm_delete ]

  def index
    load_plans_and_materials
  end

  def new
    @step = (params[:step] || 1).to_i
    @subject_type = params[:subject_type]

    case @step
    when 2
      already_planned_ids = load_current_plans.subject_ids_for_type(@subject_type)
      @subject_list = @subject_type.constantize.where.not(id: already_planned_ids).order(:name)
    when 3
      @subject = @subject_type.constantize.find(params[:subject_id])
      @form = PlanForm.new(subject_type: @subject_type, subject_id: @subject.id)
    end

    render layout: false if turbo_frame_request?
  rescue NameError
    @errors = [ "Invalid subject type" ]
    render_form_with_errors
  end

  def create
    @form = PlanForm.new(plan_params)
    @subject_type = @form.subject_type
    @subject = @subject_type.safe_constantize&.find_by(id: @form.subject_id)

    return handle_missing_subject if @subject.nil?

    begin
      @plan = @form.save(current_user, @guest_token)

      if @plan
        load_plans_and_materials
        flash.now[:notice] = "Plan created successfully."
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to plans_path }
        end
      else
        @errors = @form.errors.full_messages
        render_form_with_errors
      end

    rescue ResonatorAscensionPlanner::ValidationError, WeaponAscensionPlanner::ValidationError => e
      @errors = e.message.split("|")
      render_form_with_errors
    rescue StandardError => e
      @errors = [ "An error occurred: #{e.message}" ]
      render_form_with_errors
    end
  end

  def edit
    @form = PlanForm.from_plan(@plan)
    @subject = @plan.subject
    @subject_type = @plan.subject_type
  end

  def update
    @form = PlanForm.new(plan_params)
    @subject = @plan.subject
    @subject_type = @plan.subject_type

    begin
      if @form.save(current_user, @guest_token, @plan)
        load_plans_and_materials
        flash.now[:notice] = "Plan updated successfully."
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to plans_path }
        end
      else
        @errors = @form.errors.full_messages
        render_form_with_errors
      end

    rescue ResonatorAscensionPlanner::ValidationError, WeaponAscensionPlanner::ValidationError => e
      @errors = e.message.split("|")
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
    load_plans_and_materials
    flash.now[:notice] = "Plan deleted successfully."

    respond_to do |format|
      format.turbo_stream
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
    @plan = load_current_plans.find(params[:id])
  end

  def authorize_owner!
    is_user_owner = user_signed_in? && @plan.user_id == current_user.id
    is_guest_owner  = @plan.user_id.nil? && @plan.guest_token == @guest_token

    unless is_user_owner || is_guest_owner
      redirect_to plans_path, alert: "You don't have permission to modify this plan."
    end
  end

  def load_plans_and_materials
    @plans = load_current_plans
    @materials_summary = Plan.fetch_materials_summary(@plans)
    @materials_lookup = Material.index_by_ids(@materials_summary.keys)
  end

  def handle_missing_subject
    @errors = [ "The selected #{@subject_type || 'subject'} could not be found." ]
    render_form_with_errors
  end

  def render_form_with_errors
    plan_to_render = @form || PlanForm.from_plan(@plan || Plan.new)

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.update("plan-form-frame",
          partial: "plans/form",
          locals: {
            plan: plan_to_render,
            subject: @subject,
            subject_type: @subject_type,
            errors: @errors
          })
      }
    end
  end

  def plan_params
    core = [ :id, :subject_type, :subject_id, :current_level, :target_level, :current_ascension_rank, :target_ascension_rank ]

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
end
