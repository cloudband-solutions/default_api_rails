class SystemController < ApplicationController
  before_action :authenticate_user!, only: [:change_password]

  def health_check
    render json: { message: "ok" }
  end

  def login
    email     = params[:email]
    password  = params[:password]

    cmd = ::System::Login.new(
      email:    email,
      password: password
    )

    cmd.execute!

    if cmd.valid?
      render json: { token: generate_jwt(cmd.user.to_object) }
    else
      render json: cmd.payload, status: :unprocessable_content
    end
  end

  def change_password
    if @current_user.inactive?
      render json: { message: "forbidden" }, status: :forbidden
      return
    end

    cmd = ::System::ChangePassword.new(
      user: @current_user,
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    cmd.execute!

    if cmd.valid?
      render json: { message: "ok" }
    else
      render json: cmd.payload, status: :unprocessable_content
    end
  end
end
