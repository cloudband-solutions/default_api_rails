require 'rails_helper'

RSpec.describe 'Update user' do
  include ApiHelpers
  include_context "authentication_context"

  let(:api_url) { '/users/:id' }

  describe "PUT /users/:id", type: :request do
    context 'invalid calls' do
      it 'returns error is user is not logged in' do
        put api_url.gsub(":id", user.id)

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns not found if user is not found' do
        put api_url.gsub(":id", "non-existent"), headers: user_headers

        expect(response).to have_http_status(:not_found)
      end

      it 'returns invalid if values are already taken' do
        second_user = FactoryBot.create(:user)

        params = {
          email: user.email
        }

        put api_url.gsub(":id", second_user.id), params: params, headers: user_headers

        payload = JSON.parse(response.body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(payload['email'][0]).to eq('already taken')
      end
    end

    context 'valid calls' do
      it 'successfully updates a user' do
        params = {
          email: Faker::Internet.email,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name
        }

        put api_url.gsub(":id", user.id), params: params, headers: user_headers
        
        updated_user = User.find(user.id)

        expect(response).to have_http_status(:ok)
        expect(updated_user.email).to eq(params[:email])
        expect(updated_user.first_name).to eq(params[:first_name])
        expect(updated_user.last_name).to eq(params[:last_name])
      end
    end
  end
end
