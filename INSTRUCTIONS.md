# INSTRUCTIONS.md

## Stack

- Ruby on Rails (API only)
- RSpec for testing
- PostgreSQL for database (with `uuid` as primary key)

## Coding Convention

Use command patterns when performing business rules.

```ruby
class ExecuteSave
  def initialize(param1:, param2:)
    @param1 = param1
    @param2 = param2
  end

  def execute!
    @answer = @param1 + @param2

    @answer
  end
end
```

* Attributes like `param1` and `param2` are initialized in the constructor
* Method `execute!` executes the main business logic.
* Other methods may be programmed in

### Validation Command Pattern

Business rules that are expected to have errors will extend `Validator` class. `Validator` has a `count_errors!` method which will validate the class by checking if there are error messages for each given field.

**Example:**

```ruby
class ValidateParams < Validator
  attr_reader :param1, :param2, :payload

  def initialize(param1:, param2:)
    super()

    @param1 = param1
    @param2 = param2

    @payload = {
      param1: [],
      param2: []
    }
  end

  def execute!
    if @param1.blank?
      @payload[:param1] << "param1 required"
    end

    if @param2.blank?
      @payload[:param2] << "param2 required"
    end

    count_errors!
  end
end
```

### Writing Tests

Use the following RSpec request spec convention for CRUD endpoints (mirrors `spec/requests/users/*_spec.rb` patterns):

- Always `require 'rails_helper'`
- Include `ApiHelpers` and `include_context "authentication_context"`
- Define `let(:api_url)` for the endpoint path
- Use `describe "HTTP VERB /path", type: :request`
- Split into `context 'invalid calls'` and `context 'valid calls'`
- For invalid calls, assert `:forbidden`, `:not_found`, or `:unprocessable_content`
- For valid calls, assert `:ok` and any state changes

```ruby
require 'rails_helper'

RSpec.describe 'Widgets CRUD' do
  include ApiHelpers
  include_context "authentication_context"

  let(:api_url) { '/widgets' }
  let(:show_url) { '/widgets/:id' }

  describe "GET /widgets", type: :request do
    context 'invalid calls' do
      it 'returns error is user is not logged in' do
        get api_url

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'valid calls' do
      it 'successfully returns widgets' do
        get api_url, headers: user_headers

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /widgets/:id", type: :request do
    context 'invalid calls' do
      it 'returns not found if widget is not found' do
        get show_url.gsub(":id", "non-existent"), headers: user_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'valid calls' do
      it 'successfully returns a widget' do
        widget = FactoryBot.create(:widget)

        get show_url.gsub(":id", widget.id), headers: user_headers

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /widgets", type: :request do
    context 'invalid calls' do
      it 'returns error for missing values' do
        post api_url, headers: user_headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'valid calls' do
      it 'successfully creates a widget' do
        params = { name: "Widget A" }

        post api_url, params: params, headers: user_headers

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PUT /widgets/:id", type: :request do
    context 'invalid calls' do
      it 'returns not found if widget is not found' do
        put show_url.gsub(":id", "non-existent"), headers: user_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'valid calls' do
      it 'successfully updates a widget' do
        widget = FactoryBot.create(:widget)
        params = { name: "Widget B" }

        put show_url.gsub(":id", widget.id), params: params, headers: user_headers

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "DELETE /widgets/:id", type: :request do
    context 'invalid calls' do
      it 'returns not found if widget is not found' do
        delete show_url.gsub(":id", "non-existent"), headers: user_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'valid calls' do
      it 'successfully deletes a widget' do
        widget = FactoryBot.create(:widget)

        delete show_url.gsub(":id", widget.id), headers: user_headers

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
```

### Controller Convention

Controllers that require an authenticated user should follow the existing `AuthenticatedController` pattern and use the shared auth helpers.

- Inherit from `AuthenticatedController`
- Include `ApiHelpers` only if the controller needs helper methods not already exposed by the parent
- Use `before_action :authenticate_user!` and `before_action :authorize_active!` to ensure the current user is present and active
- Use `@current_user` for the authenticated user in actions and commands
- For resources, load via `load_resource!` and return `:not_found` when missing

```ruby
class WidgetsController < AuthenticatedController
  include ApiHelpers
  before_action :authenticate_user!
  before_action :authorize_active!
  before_action :load_resource!, only: [:show, :update, :delete]

  def index
    widgets = Widget.where(user_id: @current_user.id)
    render json: widgets.map { |w| w.to_h }
  end

  def show
    render json: @widget.to_h
  end

  def create
    cmd = ::Widgets::Save.new(
      user: @current_user,
      name: params[:name]
    )

    cmd.execute!

    if cmd.valid?
      render json: cmd.widget.to_h
    else
      render json: cmd.payload, status: :unprocessable_content
    end
  end

  def update
    cmd = ::Widgets::Save.new(
      widget: @widget,
      user: @current_user,
      name: params[:name]
    )

    cmd.execute!

    if cmd.valid?
      render json: cmd.widget.to_h
    else
      render json: cmd.payload, status: :unprocessable_content
    end
  end

  def delete
    @widget.soft_delete!
    render json: { message: "ok" }
  end

  private

  def load_resource!
    @widget = Widget.find_by_id(params[:id])
    if @widget.blank?
      render json: { message: 'not found' }, status: :not_found
    end
  end
end
```
