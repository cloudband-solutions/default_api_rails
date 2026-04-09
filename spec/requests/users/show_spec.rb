require 'rails_helper'

RSpec.describe 'Users show' do
  include ApiHelpers
  include_context "authentication_context"

  let(:api_url) { '/users/:id' }

  describe "GET /users/:id", type: :request do
    context 'invalid calls' do
      it 'returns error is user is not logged in' do
        get api_url.gsub(":id", user.id)

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns forbidden when user is not admin' do
        regular_user = FactoryBot.create(:user, role: "user")

        get api_url.gsub(":id", user.id), headers: build_jwt_header(generate_jwt(regular_user.to_h))

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to eq({ "message" => "invalid authorization" })
      end

      it 'returns not found if user is not found' do
        get api_url.gsub(":id", "non-existent"), headers: user_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'valid calls' do
      it 'successfully returns a user' do
        get api_url.gsub(":id", user.id), headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(payload["role"]).to eq(user.role)
      end
    end
  end
end
