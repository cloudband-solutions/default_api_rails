RSpec.shared_context "authentication_context" do
  include ApiHelpers

  let(:user) { FactoryBot.create(:user, roles: ["MIS"]) }
  let(:user_headers) { build_jwt_header(generate_jwt(user.to_h)) }
end
