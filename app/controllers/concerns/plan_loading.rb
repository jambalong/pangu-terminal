module PlanLoading
  def load_current_plans
    plans = if user_signed_in?
      current_user.plans.includes(:subject)
    else
      Plan.where(user_id: nil, guest_token: @guest_token).includes(:subject)
    end

    plans.order(created_at: :asc)
  end
end
