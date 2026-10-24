# The owner's side of sharing: see the link, create it, or stop sharing.
# Plans are looked up through the owner's own list, so someone else's plan is a 404.
class PlanSharesController < ApplicationController
  include PlanLoading

  before_action :set_guest_token
  before_action :set_plan

  def show
    render layout: false if turbo_frame_request?
  end

  def create
    @plan.share!
    redirect_to plan_share_path(@plan), status: :see_other
  end

  def destroy
    @plan.unshare!
    redirect_to plan_share_path(@plan), status: :see_other
  end

  private

  def set_guest_token
    cookies.permanent[:guest_token] ||= SecureRandom.uuid
    @guest_token = cookies.permanent[:guest_token]
  end

  def set_plan
    @plan = load_current_plans.find(params[:plan_id])
  end
end
