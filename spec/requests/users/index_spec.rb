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
    end

    context 'valid calls' do
      it 'successfully logs in' do
        get api_url, headers: user_headers

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
