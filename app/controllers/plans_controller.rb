class PlansController < ApplicationController
  before_action :set_guest_token
  before_action :set_plan, only: [ :edit, :update, :destroy, :confirm_delete ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy, :confirm_delete ]

  def index
    @plans = current_plans.includes(:subject).order(created_at: :desc)
    @materials_summary = Plan.fetch_materials_summary(@plans)
  end

  def new
    @step = (params[:step] || 1).to_i
    @subject_type = params[:subject_type] || params.dig(:plan, :subject_type)

    case @step
    when 2
      already_planned_ids = current_plans.planned_subject_ids(@subject_type)
      @subject_list = @subject_type.constantize.where.not(id: already_planned_ids).order(:name)
    when 3
      @subject = @subject_type.constantize.find(params[:subject_id])
      @form = PlanForm.new(subject_type: @subject_type, subject_id: @subject.id)
    end
    # Rails automatically renders new.html.erb, which uses the @variables above
  end

  def create
    @form = PlanForm.new(plan_params)
    @subject_type = @form.subject_type

    # Safe constantize to find the record
    @subject = @subject_type.safe_constantize&.find_by(id: @form.subject_id)
    @errors = []

    handle_missing_subject if @subject.nil?

    if current_plans.exists?(subject: @subject)
      @errors = [ "You already have a plan for #{@subject.name}." ]
      render_form_with_errors
    end

    begin
      @plan = @form.save(current_user, @guest_token)

      if @plan
        @materials_summary = Plan.fetch_materials_summary(current_plans)
        respond_to do |format|
          format.turbo_stream # This will look for create.turbo_stream.erb
          format.html { redirect_to plans_path }
        end
      else
        @errors = @form.errors.full_messages
        render_form_with_errors
      end

    rescue ResonatorAscensionPlanner::ValidationError, WeaponAscensionPlanner::ValidationError => e
      @errors = e.message.split("|")
      render_form_with_errors
    rescue ActiveRecord::RecordNotFound
      @errors = [ "The selected #{@subject_type} could not be found." ]
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

    render :new
  end

  def update
    @form = PlanForm.new(plan_params)
    @subject = @plan.subject
    @subject_type = @plan.subject_type

    begin
      if @form.save(current_user, @guest_token, @plan)
        respond_to { |format| format.turbo_stream }
      else
        @errors = @form.errors.full_messages
        render_form_with_errors
      end

    rescue ResonatorAscensionPlanner::ValidationError, WeaponAscensionPlanner::ValidationError => e
      @errors = e.message.split("|")
      render_form_with_errors
    rescue ActiveRecord::RecordNotFound
      @errors = [ "The selected #{@subject_type} could not be found." ]
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

    @materials_summary = Plan.fetch_materials_summary(current_plans)
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

  def handle_missing_subject
    @errors = [ "The selected #{@subject_type || 'subject'} could not be found." ]
    render_form_with_errors
  end

  def render_form_with_errors
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.update("plan-form-frame",
          partial: "plans/form",
          locals: {
            form: @form,
            subject: @subject,
            subject_type: @subject_type,
            errors: @errors
          })
      }
    end
  end

  def current_plans
    if user_signed_in?
      current_user.plans
    else
      Plan.where(user_id: nil, guest_token: @guest_token)
    end
  end

  def plan_params
    core = [ :subject_type, :subject_id, :current_level, :target_level, :current_ascension_rank, :target_ascension_rank ]

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
