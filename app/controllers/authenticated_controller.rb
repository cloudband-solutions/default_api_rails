class AuthenticatedController < ApplicationController
  include ApiHelpers

  before_action :authenticate_user!

  def authorize_active!
    if not @current_user.present?
      render json: { message: "unauthorized" }, status: :unauthorized
    elsif @current_user.inactive?
      render json: { message: "forbidden" }, status: :forbidden
    end
  end

  def authorize_admin!
    if not @current_user.admin?
      render json: { message: "invalid authorization" }, status: :forbidden
    end
  end
end
