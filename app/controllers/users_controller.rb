class UsersController < AuthenticatedController
  include ApiHelpers
  before_action :authenticate_user!
  before_action :authorize_active!

  before_action :load_resource!, only: [:show, :update, :delete]

  def index
    users = User.order("last_name ASC")

    if params[:query].present?
      users = users.search(params[:query])
    end

    if params[:status].present?
      users = users.where(status: params[:status])
    end

    users = users.page(params[:page]).per(params[:per_page] || ITEMS_PER_PAGE)

    records = users.map{ |o| o.to_h }

    render json: {
      records: records,
      total_pages: users.total_pages,
      current_page: users.current_page,
      next_page: users.next_page,
      prev_page: users.prev_page
    }
  end

  def show
    render json: @user.to_h
  end

  def update
    cmd = ::Users::Save.new(
      user: @user,
      email: params[:email],
      first_name: params[:first_name],
      last_name: params[:last_name],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    cmd.execute!

    if cmd.valid?
      render json: cmd.user.to_h
    else
      render json: cmd.payload, status: :unprocessable_content
    end
  end

  def create
    cmd = ::Users::Save.new(
      email: params[:email],
      first_name: params[:first_name],
      last_name: params[:last_name],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    cmd.execute!

    if cmd.valid?
      render json: cmd.user.to_h
    else
      render json: cmd.payload, status: :unprocessable_content
    end
  end

  def delete
    @user.soft_delete!

    render json: { message: "ok" }
  end

  private

  def load_resource!
    @user = User.find_by_id(params[:id])

    if @user.blank?
      render json: { message: 'not found' }, status: :not_found
    end
  end
end
