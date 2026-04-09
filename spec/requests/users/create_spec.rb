require 'rails_helper'

RSpec.describe 'Users create' do
  include ApiHelpers
  include_context "authentication_context"

  let(:api_url) { '/users' }

  describe "POST /users", type: :request do
    context 'invalid calls' do
      it 'returns error is user is not logged in' do
        post api_url

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns forbidden when user is not admin' do
        regular_user = FactoryBot.create(:user, role: "user")

        post api_url, headers: build_jwt_header(generate_jwt(regular_user.to_h))

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to eq({ "message" => "invalid authorization" })
      end
      
      it 'returns error for missing values' do
        post api_url, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload['email']).to eq(['required'])
        expect(payload['first_name']).to eq(['required'])
        expect(payload['last_name']).to eq(['required'])
        expect(payload['password']).to eq(['required'])
        expect(payload['password_confirmation']).to eq(['required'])
      end

      it 'returns error for unique values' do
        params = {
          email: user.email
        }

        post api_url, params: params, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload['email']).to eq(['already taken'])
      end

      it 'returns error for invalid values' do
        params = {
          email: 'invalid-format'
        }

        post api_url, params: params, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload['email']).to eq(['invalid format'])
      end

      it 'returns error if passwords do not match' do
        params = {
          password: 'A',
          password_confirmation: 'B'
        }

        post api_url, params: params, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload['password']).to eq(['does not match'])
        expect(payload['password_confirmation']).to eq(['does not match'])
      end

      it 'returns error for invalid role' do
        params = {
          email: Faker::Internet.email,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          role: "manager",
          password: "password",
          password_confirmation: "password"
        }

        post api_url, params: params, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload["role"]).to eq(["invalid role"])
      end
    end

    context 'valid calls' do
      it 'defaults created users to role user when role is omitted' do
        params = {
          email: Faker::Internet.email,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          password: "password",
          password_confirmation: "password"
        }

        post api_url, params: params, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(payload["role"]).to eq("user")
      end

      it 'successfully creates a user with the provided role' do
        params = {
          email: Faker::Internet.email,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          role: "admin",
          password: "password",
          password_confirmation: "password"
        }

        post api_url, params: params, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(payload["role"]).to eq("admin")
      end
    end
  end
end
