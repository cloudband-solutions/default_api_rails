# AGENTS.md

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

## Engineering Workflow

Work like a careful senior engineer preparing a change for review. The default sequence is:

**understand → inspect conventions → plan → implement → validate → self-review → refine → re-validate → final diff review → stop when stable**

### 1. Understand Before Editing

Before modifying code:

- Read the files surrounding the requested change, including relevant tests and configuration.
- Look for more specific `AGENTS.md` or `INSTRUCTIONS.md` files, project documentation, and nearby working implementations.
- Search the repository for similar behavior before designing anything new.
- Determine which conventions apply and which architectural layer owns the change.
- Prefer repository conventions over generic Rails or ecosystem conventions whenever this project already establishes a pattern.
- Reuse an existing pattern rather than introducing a competing one.

When unsure, inspect the closest working implementation, its tests, and relevant documentation before making an assumption. Do not invent a new service, command, response, error-handling, or file-organization style merely because it is common elsewhere.

### 2. Plan the Change

For anything beyond a trivial edit, form a short implementation plan before changing files. It may remain internal unless sharing it would help coordination. Identify:

- files likely to change and existing abstractions to reuse;
- dependencies and responsibilities across components;
- expected behavior and important edge or error cases;
- targeted tests or other validation needed;
- architectural, security, or portability concerns.

Prefer the smallest change that cleanly satisfies the requirement. Avoid speculative abstractions and unrelated cleanup.

### 3. Implement Deliberately

During implementation:

- Follow nearby code and preserve separation between controllers, operations, models, and other layers.
- Reuse canonical helpers, operations, components, and utilities instead of duplicating their logic.
- Keep public interfaces small, predictable, and consistent with existing callers.
- Avoid unnecessary dependencies and environment-specific shortcuts; prefer modular, portable code and project configuration.
- Do not refactor unrelated code unless it is necessary to make the requested change clean.

If the request appears to conflict with a project convention, determine whether the convention still applies before proceeding. Any deviation must have a concrete technical reason and be intentional rather than accidental.

### 4. Validate the Change

Run the most relevant available checks. Start with targeted request or model specs, then use broader specs, linters, formatters, type checks, build or framework checks when appropriate. Manually inspect behavior when automated coverage is insufficient.

Do not silently ignore a failure. Determine whether it was caused by the change, was already present, or exposes a flaw that requires another implementation pass. Document unrelated failures in the final handoff.

### 5. Self-Review and Refine

Do not consider the task complete after the first implementation. Inspect the complete diff as if reviewing another developer's pull request. Check:

- **Correctness:** The requested behavior is present, assumptions are valid, and important edge and failure paths are handled.
- **Conventions:** Naming, file placement, response shapes, and layer boundaries match nearby code; no existing helper or operation pattern was bypassed.
- **Simplicity:** There is no premature abstraction, unnecessary code, or duplicated canonical logic.
- **Maintainability:** Responsibilities and dependencies are clear, and a future developer can find the right extension point.
- **Portability:** There are no unnecessary machine, shell, operating-system, path, host, environment-variable, or developer-setup assumptions.
- **Security and failures:** Inputs are handled appropriately; secrets and environment-specific values are not hard-coded; failures cannot produce misleading or unsafe behavior.

Use this loop when review or validation reveals a concrete issue:

1. Inspect.
2. Plan.
3. Implement.
4. Validate.
5. Review the diff.
6. Identify concrete issues.
7. Refine the implementation.
8. Validate again.

Repeat only while a meaningful correctness, architectural, convention, maintainability, portability, security, or testing issue remains. Do not iterate indefinitely over cosmetic preferences.

### 6. Refactoring Scope

If a feature exposes poor structure, refactor only what is needed to implement the requested behavior cleanly. Preserve observable behavior unless changing it is part of the requirement, and keep refactoring logically separable from behavioral changes where practical. Leave beneficial but unnecessary repository-wide redesigns for a separate change.

### 7. Completion and Final Diff Review

Consider a change stable only when:

- the requested behavior is implemented using repository conventions;
- relevant validation passes, or remaining unrelated failures are understood and documented;
- no known correctness issue, important unhandled edge case, unnecessary duplication, or avoidable new architecture remains;
- the appropriate existing abstraction was used;
- no accidental or unrelated changes remain;
- another review pass reveals no concrete material improvement worth making.

Before finishing, inspect the full diff one final time for debug statements, temporary files, commented-out or dead code, unused imports, accidental formatting changes, hard-coded paths or URLs, duplicated logic, inconsistent naming, missing tests, and changes outside the requested scope. Remove accidental changes, then stop. The goal is a stable, conventional, maintainable implementation with no known material issues—not theoretical perfection.

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

- Missing `Authorization` header returns `401 unauthorized` with `{ message: "authentication required" }`
- Invalid token or missing active user returns `401 unauthorized` with `{ message: "invalid authorization" }`
- Failed `authorize_active!` or `authorize_admin!` returns `403 forbidden`

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

- `:unauthorized` for missing auth header or invalid auth token
- `:forbidden` for authenticated users who fail role or active-state checks
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
