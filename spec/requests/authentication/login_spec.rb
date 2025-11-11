require 'rails_helper'

RSpec.describe 'Login' do
  include ApiHelpers
  include_context "authentication_context"

  let(:active_user) { FactoryBot.create(:active_user) }
  let(:inactive_user) { FactoryBot.create(:inactive_user) }
  let(:api_url) { '/login' }

  describe "POST /login", type: :request do
    context 'invalid calls' do
      it 'returns error on no parameters passed' do
        post api_url

        expect(response).to have_http_status(:unprocessable_content)

        payload = JSON.parse(response.body)

        expect(payload['email']).to eq(['email required'])
        expect(payload['password']).to eq(['password required'])
      end

      it 'returns error on no user found' do
        invalid_email = 'test'
        invalid_password = 'test'

        post api_url, params: { email: invalid_email, password: invalid_password }

        expect(response).to have_http_status(:unprocessable_content)

        payload = JSON.parse(response.body)

        expect(payload['email']).to eq(['user not found'])
      end

      it 'returns error on invalid email / password' do
        invalid_password = 'test'

        post api_url, params: { email: user.email, password: invalid_password }

        expect(response).to have_http_status(:unprocessable_content)

        payload = JSON.parse(response.body)

        expect(payload['password']).to eq(['invalid password'])
      end

      it 'returns error on inactive user' do
        post api_url, params: { email: inactive_user.email, password: 'password' }

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload["email"][0]).to eq("user inactive")
      end
    end

    context 'valid calls' do
      it 'successfully logs in' do
        post api_url, params: { email: active_user.email, password: 'password' }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
