module PlanLoading
  def load_current_plans
    plans = if user_signed_in?
      current_user.plans.preload(:subject)
    else
      Plan.where(user_id: nil, guest_token: @guest_token).preload(:subject)
    end

    plans.order(created_at: :asc)
  end
end
