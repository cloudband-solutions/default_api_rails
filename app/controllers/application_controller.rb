class ApplicationController < ActionController::API
  include ApiHelpers

  def authenticate_user!
    if request.headers["Authorization"].blank?
      render json: { message: "authentication required" }, status: :unauthorized
      return
    end

    jwt_token = request.headers["Authorization"].split(" ")[1]
    payload = decode_jwt(jwt_token)[0]

    @current_user = User.find_by_id(payload["id"])

    if @current_user.blank?
      render json: { message: "invalid authorization" }, status: :unauthorized
    end
  rescue JWT::DecodeError, JWT::ExpiredSignature
    render json: { message: "invalid authorization" }, status: :unauthorized
  end
end
