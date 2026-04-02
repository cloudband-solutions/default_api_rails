# INSTRUCTIONS.md

## Purpose

This repository is a Rails API template. When building on top of it, follow the patterns already present in the shipped `system` and `users` features instead of defaulting to generic Rails CRUD scaffolding.

This guide is written for AI agents and contributors so new features fit the template's structure, response shapes, and test style.

## Stack Summary

- Rails API application
- PostgreSQL
- UUID primary keys by default
- RSpec for tests
- FactoryBot and Faker for test data
- Kaminari for pagination
- JWT-based authentication using helpers in `ApiHelpers`

## Core Architectural Pattern

This template uses **thin controllers** and **operation objects** for business logic.

- Controllers should parse request params, enforce authorization, load resources, invoke an operation when business rules are involved, and render JSON.
- Business rules and validation belong in `app/operations/...`.
- Models hold persistence concerns, scopes, simple derived helpers, and serialization helpers like `to_h` / `to_object`.
- Request specs are the main API contract and should be written alongside the feature.

Do not introduce fat controllers or bury feature logic directly in routes, concerns, or model callbacks when an operation object is the clearer fit.

## Existing Template Conventions

### Routes

Routes are split into files under `config/routes/*.rb` and composed from `config/routes.rb`.

Current pattern:

```ruby
Rails.application.routes.draw do
  draw :system
  draw :users
end
```

When adding a feature:

- Add a dedicated route file such as `config/routes/widgets.rb`
- Register it from `config/routes.rb` with `draw :widgets`
- Match the existing explicit route style instead of switching to `resources`

Example:

```ruby
get "/widgets", to: "widgets#index"
get "/widgets/:id", to: "widgets#show"
post "/widgets", to: "widgets#create"
put "/widgets/:id", to: "widgets#update"
delete "/widgets/:id", to: "widgets#delete"
```

Use `delete` as the controller action name if you are following the template's CRUD naming, because that is what the current codebase uses.

### Controllers

Controllers are API-only and return JSON directly.

- Public endpoints inherit from `ApplicationController`
- Authenticated endpoints inherit from `AuthenticatedController`
- Admin-only endpoints call `authorize_admin!`
- Active-user-only endpoints call `authorize_active!`
- Resource lookups are usually done in a private `load_resource!` method

Current auth behavior is important:

- Missing `Authorization` header returns `403 forbidden` with `{ message: "authentication required" }`
- Invalid token or missing active user returns `403 forbidden` with `{ message: "invalid authorization" }`
- Failed `authorize_active!` or `authorize_admin!` returns `401 unauthorized`

Keep those response patterns consistent unless you are intentionally changing the template itself.

Example controller shape:

```ruby
class WidgetsController < AuthenticatedController
  before_action :authenticate_user!
  before_action :authorize_active!
  before_action :authorize_admin!
  before_action :load_resource!, only: [:show, :update, :delete]

  def index
    widgets = Widget.order("created_at DESC")
    widgets = widgets.page(params[:page]).per(params[:per_page] || ITEMS_PER_PAGE)

    render json: {
      records: widgets.map(&:to_h),
      total_pages: widgets.total_pages,
      current_page: widgets.current_page,
      next_page: widgets.next_page,
      prev_page: widgets.prev_page
    }
  end

  def show
    render json: @widget.to_h
  end

  def create
    cmd = ::Widgets::Save.new(
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
    @widget.destroy!
    render json: { message: "ok" }
  end

  private

  def load_resource!
    @widget = Widget.find_by_id(params[:id])

    if @widget.blank?
      render json: { message: "not found" }, status: :not_found
    end
  end
end
```

### Operation Objects

Business logic belongs in `app/operations/<feature>/...`.

Current conventions:

- Namespace by feature, for example `Users::Save` or `System::Login`
- Instantiate with explicit keyword arguments
- Expose result objects through readers such as `user`
- Expose validation payload through `payload`
- Call `execute!` as the entry point
- If validation is expected, inherit from `Validator`

Example:

```ruby
module Widgets
  class Save < Validator
    attr_reader :widget, :payload

    def initialize(widget: nil, name:)
      super()

      @widget = widget
      @name = name
      @payload = {
        name: []
      }
    end

    def execute!
      validate!

      return if invalid?

      @widget ||= Widget.new
      @widget.name = @name if @name.present?
      @widget.save!
    end

    private

    def validate!
      if @widget.blank? && @name.blank?
        @payload[:name] << "required"
      end

      count_errors!
    end
  end
end
```

### Validation Pattern

Use the provided `Validator` base class when the operation needs structured validation errors.

The pattern in this template is:

- Initialize `@payload` as a hash whose values are arrays
- Push human-readable error strings into those arrays
- Call `count_errors!`
- Controllers check `cmd.valid?`
- Invalid requests render `cmd.payload` with `status: :unprocessable_content`

Example payload shape:

```ruby
{
  email: ["required"],
  password: ["does not match"]
}
```

Do not switch to a different error envelope for new features unless you are intentionally standardizing the whole app.

### Models

Models in this template currently do four things:

- Define validations and scopes
- Hold lightweight derived helpers like `full_name`
- Provide JSON-ready serialization helpers through `to_h` and `to_object`
- Provide simple persistence helpers such as `soft_delete!`

When adding a new model:

- Keep serialization logic close to the model if the rest of the template already does so
- Add a `to_object` and `to_h` pair if the resource is rendered directly by controllers
- Prefer scopes for common filters used by controllers

Follow the UUID convention. The app generator is configured with:

```ruby
Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

### Authentication and Helpers

`ApiHelpers` contains the shared auth and crypto helpers used by both controllers and specs.

Important helpers already in use:

- `build_jwt_header(token)`
- `generate_jwt(user_hash)`
- `decode_jwt(token)`
- `generate_password_hash(password)`
- `password_match?(password, password_hash)`
- `ITEMS_PER_PAGE`

If a new feature needs pagination or JWT auth, reuse these helpers rather than reimplementing them.

## How To Add A New Feature

Use this checklist.

1. Add or update the database model and migration.
2. Add model validations, scopes, and `to_object` / `to_h` helpers if the model is rendered directly.
3. Add an operation object under `app/operations/<feature>/` for create, update, search, or other business rules.
4. Add a controller that stays thin and delegates validation-heavy logic to the operation.
5. Add a route fragment under `config/routes/<feature>.rb`.
6. Register the route fragment from `config/routes.rb`.
7. Add a factory under `spec/factories/`.
8. Add request specs under `spec/requests/<feature>/`.
9. Add model specs for non-trivial model behavior.
10. Run the relevant specs.

## Request Spec Conventions

This template relies heavily on request specs. New endpoints should follow the same style as the `users` and `authentication` specs.

### Structure

- Always `require "rails_helper"`
- Use `describe "HTTP_VERB /path", type: :request`
- Prefer `let(:api_url)` for endpoint paths
- Split examples into `context "invalid calls"` and `context "valid calls"` where it helps
- Parse response bodies with `JSON.parse(response.body)` when asserting payloads

### Authenticated Specs

For authenticated endpoints:

- `include ApiHelpers`
- `include_context "authentication_context"`
- Use `user_headers` for an authenticated admin request
- Override `let(:user_role)` or `let(:user_status)` when needed

The shared context currently provides:

```ruby
let(:user_role) { "admin" }
let(:user_status) { "active" }
let(:user) { FactoryBot.create(:user, role: user_role, status: user_status) }
let(:user_headers) { build_jwt_header(generate_jwt(user.to_h)) }
```

### What To Assert

Match the existing response contract:

- `:forbidden` for missing auth header or invalid auth token
- `:unauthorized` for authenticated users who fail role or active-state checks
- `:not_found` when a resource cannot be loaded
- `:unprocessable_content` for validation failures
- `:ok` for successful requests

Also assert behavior, not just status codes:

- Record creation or updates
- Soft-delete behavior where relevant
- Returned payload shape
- Pagination envelope for index endpoints

## Factory Conventions

Use `FactoryBot` for test setup.

- Keep factories in `spec/factories/*.rb`
- Use traits for role or state variants where appropriate
- Reuse existing password helpers from `ApiHelpers`

The existing `user` factory is the reference for authenticated resources.

## Feature Design Rules For Agents

When implementing a new feature, prefer these decisions:

- Reuse the `AuthenticatedController` flow for protected endpoints
- Reuse `Validator` when the endpoint needs field-level error messages
- Reuse `ITEMS_PER_PAGE` and Kaminari for paginated index endpoints
- Reuse `{ message: "not found" }` and `{ message: "ok" }` patterns where they already apply
- Reuse model `to_h` serialization in controllers
- Reuse explicit route declarations in route fragments

Avoid these mistakes:

- Do not introduce Rails scaffold-generated controllers or views
- Do not move business rules into controllers
- Do not switch a single feature to a different error response format
- Do not introduce serializers, service layers, or form objects unless the template is being intentionally evolved in that direction
- Do not use `resources` routing if you are trying to stay aligned with the current route style
- Do not assume Rails defaults for auth or error handling; copy the existing response contract

## Recommended Prompting Context For AI Agents

When asking an AI agent to build a feature in this repository, include the following expectations in the prompt:

- Follow existing patterns from `UsersController`, `SystemController`, `Users::Save`, `System::Login`, and the request specs under `spec/requests/users/`
- Keep controllers thin and move business logic into `app/operations`
- Use `Validator` and `payload` arrays for validation errors
- Add explicit routes in `config/routes/<feature>.rb` and register them with `draw`
- Use request specs as the primary test coverage
- Preserve current status codes and JSON response shapes
- Use UUID-friendly ActiveRecord models and FactoryBot factories

Suggested prompt fragment:

```text
Implement the feature using this template's existing conventions. Mirror the patterns used by UsersController and Users::Save: thin controller, operation object under app/operations, payload-based validation via Validator, explicit route fragment under config/routes, JSON responses via model to_h, and RSpec request specs that cover invalid and valid calls.
```

## Primary Reference Files

Agents should inspect these files before making structural decisions:

- `app/controllers/application_controller.rb`
- `app/controllers/authenticated_controller.rb`
- `app/controllers/system_controller.rb`
- `app/controllers/users_controller.rb`
- `app/helpers/api_helpers.rb`
- `app/models/user.rb`
- `app/operations/system/login.rb`
- `app/operations/users/save.rb`
- `app/operations/validator.rb`
- `config/routes.rb`
- `config/routes/system.rb`
- `config/routes/users.rb`
- `spec/support/authentication_context.rb`
- `spec/factories/users.rb`
- `spec/requests/authentication/login_spec.rb`
- `spec/requests/users/create_spec.rb`
- `spec/requests/users/index_spec.rb`
- `spec/requests/users/show_spec.rb`
- `spec/requests/users/update_spec.rb`
- `spec/requests/users/delete_spec.rb`

## Definition Of Done For New Features

A feature is aligned with this template when:

- Routes live in a dedicated route fragment and are wired through `draw`
- Controller actions stay small and readable
- Business rules live in an operation object
- Validation errors are returned through `payload`
- JSON output uses the same style as the existing resources
- Request specs cover both failure and success paths
- Factories and model helpers support the new tests cleanly
