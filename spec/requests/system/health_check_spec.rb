require 'rails_helper'

Rails.describe 'Health Check' do
  let (:api_url) { "/system/health_check" }

  describe "GET /system/health_check", type: :request do
    context "valid calls" do
      it "returns successful if reachable" do
        get api_url
        
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
