class AuthenticationController < ApplicationController
  def authorize_active!
    if not @current_user.present?
      render json: { message: "unauthorized" }, status: :unauthorized
    elsif @current_user.inactive?
      render json: { message: "unauthorized" }, status: :unauthorized
    end
  end
end
