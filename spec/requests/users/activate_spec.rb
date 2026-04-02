require 'rails_helper'

RSpec.describe 'Activate user' do
  include ApiHelpers
  include_context "authentication_context"

  let(:api_url) { '/users/:id/activate' }

  describe "PUT /users/:id/activate", type: :request do
    let(:pending_user) { FactoryBot.create(:user, status: "pending") }

    context 'invalid calls' do
      it 'returns error if user is not logged in' do
        put api_url.gsub(":id", pending_user.id)

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns unauthorized when user is not admin' do
        regular_user = FactoryBot.create(:user, role: "user")

        put api_url.gsub(":id", pending_user.id), headers: build_jwt_header(generate_jwt(regular_user.to_h))

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({ "message" => "invalid authorization" })
      end

      it 'returns not found if user is not found' do
        put api_url.gsub(":id", "non-existent"), headers: user_headers

        expect(response).to have_http_status(:not_found)
      end

      it 'returns invalid when user is not pending' do
        put api_url.gsub(":id", user.id), headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload["status"]).to eq(["cannot activate"])
      end
    end

    context 'valid calls' do
      it 'successfully activates a pending user' do
        put api_url.gsub(":id", pending_user.id), headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(pending_user.reload.status).to eq("active")
        expect(payload["status"]).to eq("active")
      end
    end
  end
end
