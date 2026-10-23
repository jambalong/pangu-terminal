class Users::RegistrationsController < Devise::RegistrationsController
  # New accounts are created through OAuth. The email sign-up form is only a
  # fallback while no provider is configured, so production is never left
  # without a way to sign up.
  before_action :require_signup_fallback, only: [ :new, :create ]

  protected

  def after_update_path_for(resource)
    if params[:user][:sol3_phase].present? && params[:user][:password].blank?
      authenticated_root_path
    else
      edit_user_registration_path
    end
  end

  def update_resource(resource, params)
    if updating_only_sol3_phase?(params)
      params.delete(:current_password)
      resource.update_without_password(params)
    elsif !resource.password?
      # OAuth-only accounts have no current password to confirm; they are
      # already signed in. Setting a password here makes the email form usable.
      resource.update(params.except(:current_password))
    else
      super
    end
  end

  private

  def require_signup_fallback
    return unless OauthProviders.any?

    redirect_to new_user_session_path, alert: "Create your account by signing in with Google or Discord."
  end

  def updating_only_sol3_phase?(params)
    params.keys.map(&:to_s) == [ "sol3_phase" ]
  end
end
