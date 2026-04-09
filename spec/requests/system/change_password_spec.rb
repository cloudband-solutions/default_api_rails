require 'rails_helper'

RSpec.describe 'Change password' do
  include ApiHelpers
  include_context "authentication_context"

  let(:api_url) { '/system/change_password' }

  describe "PUT /system/change_password", type: :request do
    context 'invalid calls' do
      it 'returns error if user is not logged in' do
        put api_url

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq({ "message" => "authentication required" })
      end

      it 'returns forbidden when user is inactive' do
        inactive_user = FactoryBot.create(:inactive_user)

        put api_url, headers: build_jwt_header(generate_jwt(inactive_user.to_h))

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to eq({ "message" => "forbidden" })
      end

      it 'returns validation errors for missing values' do
        put api_url, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload['password']).to eq(['required'])
        expect(payload['password_confirmation']).to eq(['required'])
      end

      it 'returns validation errors when passwords do not match' do
        params = {
          password: 'password-one',
          password_confirmation: 'password-two'
        }

        put api_url, params: params, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload['password']).to eq(['does not match'])
        expect(payload['password_confirmation']).to eq(['does not match'])
      end
    end

    context 'valid calls' do
      it 'successfully changes the password' do
        params = {
          password: 'new-password',
          password_confirmation: 'new-password'
        }

        put api_url, params: params, headers: user_headers

        expect(response).to have_http_status(:ok)
        expect(password_match?('new-password', user.reload.encrypted_password)).to eq(true)
      end
    end
  end
end
