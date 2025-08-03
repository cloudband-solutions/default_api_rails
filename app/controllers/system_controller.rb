class SystemController < ApplicationController
  def health_check
    render json: { message: "ok" }
  end
end
