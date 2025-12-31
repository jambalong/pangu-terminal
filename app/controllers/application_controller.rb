class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # A Devise helper that runs after successful login/signup
  def after_sign_in_path_for(resource)
    sync_guest_plans(resource)
    plans_path # Redirect them to their newly synced dashboard
  end

  private

  def sync_guest_plans(user)
    token = cookies.permanent[:guest_token]

    if token.present?
      # Update all "Guest" plans with this cookie to belong to the new User
      Plan.where(guest_token: token, user_id: nil).update_all(user_id: user.id)
      # Optional: Clean up the cookie if you want a fresh start
      # cookies.delete(:guest_token)
    end
  end
end
