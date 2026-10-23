class PagesController < ApplicationController
  def home
  end

  def privacy
  end

  def user_manual
    render layout: "user_manual"
  end
end
