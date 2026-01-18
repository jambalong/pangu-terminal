class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # A Devise helper that runs after successful login/signup
  def after_sign_in_path_for(resource)
    sync_guest_plans(resource)
    authenticated_root_path
  end

  private

  def sync_guest_plans(user)
    token = cookies.permanent[:guest_token]

    if token.present?
      Plan.where(guest_token: token, user_id: nil).each do |guest_plan|
        subject_id = guest_plan.plan_data.dig("input", "subject_id")

        next if subject_id.blank?

        existing_plan = user.plans.where("plan_data->'input'->>'subject_id' = ?", subject_id.to_s).exists?

        if existing_plan
          guest_plan.destroy
        else
          guest_plan.update(user_id: user.id, guest_token: nil)
        end
      end
      cookies.delete(:guest_token)
    end
  end
end
