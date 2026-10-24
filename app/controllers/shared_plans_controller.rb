# The public, read-only page for a shared plan: the subject and its material
# totals, nothing about who owns it. Not indexed, never cached, 404 for an
# unknown or revoked token.
class SharedPlansController < ApplicationController
  def show
    @plan = Plan.preload(:subject).find_by!(share_token: params[:token])
    raise ActiveRecord::RecordNotFound, "shared plan has no subject" unless @plan.subject
    @materials_lookup = Material.index_by_ids((@plan.plan_data["output"] || {}).keys)

    expires_now
    response.set_header("X-Robots-Tag", "noindex, nofollow")
  end
end
