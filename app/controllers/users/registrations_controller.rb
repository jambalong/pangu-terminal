# Account settings and deletion. Accounts are created through OAuth, so the
# sign-up actions are not routed, and with no password there is nothing to
# confirm before changing a username or SOL3 phase.
class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_update_path_for(resource)
    params[:user][:sol3_phase].present? ? authenticated_root_path : edit_user_registration_path
  end

  def update_resource(resource, params)
    resource.update_without_password(params)
  end
end
