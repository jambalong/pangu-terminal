class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2 = handle_auth
  def discord = handle_auth

  def failure
    redirect_to(user_signed_in? ? edit_user_registration_path : new_user_session_path,
                alert: "Sign-in with that provider did not complete. Please try again.")
  end

  private

  def handle_auth
    auth = request.env["omniauth.auth"]
    return failure if auth.blank? || auth.uid.blank?

    if user_signed_in?
      link_identity(auth)
    else
      sign_in_with(auth)
    end
  end

  # Only ever links to the signed-in user. Never matches an existing account by
  # email, which would allow account takeover through an unverified provider email.
  def link_identity(auth)
    identity = Identity.find_by(provider: auth.provider, uid: auth.uid.to_s)

    if identity.nil?
      current_user.identities.create!(provider: auth.provider, uid: auth.uid.to_s)
      redirect_to edit_user_registration_path, notice: "#{OauthProviders.label(auth.provider)} linked."
    elsif identity.user_id == current_user.id
      redirect_to edit_user_registration_path, notice: "#{OauthProviders.label(auth.provider)} is already linked."
    else
      redirect_to edit_user_registration_path,
                  alert: "That #{OauthProviders.label(auth.provider)} account is already linked to another Pangu Terminal account."
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to edit_user_registration_path, alert: "Could not link that account. Please try again."
  end

  def sign_in_with(auth)
    identity = Identity.find_by(provider: auth.provider, uid: auth.uid.to_s)
    new_account = identity.nil?
    user = identity&.user || create_user_from(auth)
    return failure unless user

    user.update(display_name: User.generate_display_name) if user.display_name.blank?
    if new_account
      flash[:notice] = "Welcome! You are signed in as #{user.display_name}. You can change that name in Account Settings."
    elsif is_navigational_format?
      set_flash_message(:notice, :success, kind: OauthProviders.label(auth.provider))
    end
    sign_in_and_redirect user, event: :authentication
  end

  def create_user_from(auth)
    user = User.new(display_name: User.generate_display_name)
    user.identities.build(provider: auth.provider, uid: auth.uid.to_s)
    user.save ? user : nil
  rescue ActiveRecord::RecordNotUnique
    # A concurrent callback created the same identity first.
    Identity.find_by(provider: auth.provider, uid: auth.uid.to_s)&.user
  end
end
