class ApplicationController < ActionController::API
  def authenticate_user!
    if request.headers["Authorization"].blank?
      render json: { message: "authentication required" }, status: :forbidden
    else
      jwt_token = request.headers["Authorization"].split(" ")[1]
      payload = decode_jwt(jwt_token)[0]

      @current_user = User.active.find_by_id(payload["id"])

      if @current_user.blank?
        render json: { message: "invalid authorization" }, status: :forbidden
      end
    end
  end
end
