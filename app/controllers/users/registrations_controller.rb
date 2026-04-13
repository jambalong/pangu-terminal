class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_update_path_for(resource)
    if params[:user][:sol3_phase].present? && params[:user][:password].blank?
      authenticated_root_path
    else
      edit_user_registration_path
    end
  end

  def update_resource(resource, params)
      if params[:password].blank? && params[:password_confirmation].blank?
        params.delete(:current_password)
        resource.update_without_password(params)
      else
        super
      end
    end
end
