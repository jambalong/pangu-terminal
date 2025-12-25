class PlansController < ApplicationController
  before_action :set_planner_id

  def index
    @plans = Plan.where(planner_id: @planner_id).order(created_at: :desc)
  end

  def new
    @step = (params[:step] || 1).to_i
    @plan_type = params[:plan_type]
    @items = []
    @item = nil

    case @step
    when 2
      @items = (@plan_type == "Resonator" ? Resonator : Weapon).order(:name)
    when 3
      @item = (@plan_type == "Resonator" ? Resonator : Weapon).find(params[:item_id])
    end
    # Rails automatically renders new.html.erb, which uses the @variables above
  end

  def create
    plan_type = params[:plan_type]

    begin
      if plan_type == "Resonator"
        item = Resonator.find_by!(id: params[:item_id])
        planner = ResonatorAscensionPlanner.new(
          resonator: item,
          current_level: params[:current_level],
          target_level: params[:target_level],
          current_ascension_rank: params[:current_ascension_rank],
          target_ascension_rank: params[:target_ascension_rank],
          current_skill_levels: params[:current_skill_levels] || {},
          target_skill_levels: params[:target_skill_levels] || {},
          current_forte_nodes: params[:current_forte_nodes] || {},
          target_forte_nodes: params[:target_forte_nodes] || {}
        )
      else
        item = Weapon.find_by!(id: params[:item_id])
        planner = WeaponAscensionPlanner.new(
          weapon: item,
          current_level: params[:current_level],
          target_level: params[:target_level],
          current_ascension_rank: params[:current_ascension_rank],
          target_ascension_rank: params[:target_ascension_rank]
        )
      end

      output_data = planner.call

      input_data = {
        name: item.name,
        current_level: params[:current_level],
        target_level: params[:target_level],
        current_ascension_rank: params[:current_ascension_rank],
        target_ascension_rank: params[:target_ascension_rank]
      }

      if plan_type == "Resonator"
        input_data.merge!({
          current_skill_levels: params[:current_skill_levels],
          target_skill_levels: params[:target_skill_levels],
          current_forte_nodes: params[:current_forte_nodes],
          target_forte_nodes: params[:target_forte_nodes]
        })
      end

      @plan = Plan.new(
        planner_id: @planner_id,
        plan_type: plan_type,
        plan_data: {
          input: input_data,
          output: output_data
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
      @errors = [ "Please select a valid #{plan_type}." ]
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
end
