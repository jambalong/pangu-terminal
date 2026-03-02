class ApiKeysController < ApplicationController
  before_action :authenticate_user!

  def create
    @api_key = current_user.api_keys.build(name: params.require(:name))
    if @api_key.save
      flash[:api_token] = @api_key.raw_token
      flash[:notice] = "API Key \"#{@api_key.name}\" generated successfully."
    else
      flash[:alert] = @api_key.errors.full_messages.to_sentence
    end

    redirect_to "#{edit_user_registration_path}#api-keys"
  end

  def destroy
    @api_key = current_user.api_keys.find(params[:id])
    @api_key.destroy
    flash[:notice] = "API Key \"#{@api_key.name}\" revoked successfully."
    redirect_to "#{edit_user_registration_path}#api-keys"
  end
end
