class IdentitiesController < ApplicationController
  before_action :authenticate_user!

  def destroy
    identity = current_user.identities.find(params[:id])

    if current_user.can_unlink?(identity)
      identity.destroy
      redirect_to edit_user_registration_path, notice: "#{identity.provider_label} unlinked."
    else
      redirect_to edit_user_registration_path,
                  alert: "Link another sign-in provider before unlinking #{identity.provider_label}."
    end
  end
end
