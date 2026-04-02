require 'rails_helper'

RSpec.describe 'Users index' do
  include ApiHelpers
  include_context "authentication_context"

  let(:api_url) { '/users' }

  describe "GET /users", type: :request do
    context 'invalid calls' do
      it 'returns error is user is not logged in' do
        get api_url

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns unauthorized when user is not admin' do
        regular_user = FactoryBot.create(:user, role: "user")

        get api_url, headers: build_jwt_header(generate_jwt(regular_user.to_h))

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({ "message" => "invalid authorization" })
      end
    end

    context 'valid calls' do
      it 'successfully logs in' do
        get api_url, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(payload["records"].first["role"]).to be_present
      end
    end
  end
end
