class SystemController < ApplicationController
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
end
