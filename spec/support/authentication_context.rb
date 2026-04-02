RSpec.shared_context "authentication_context" do
  include ApiHelpers

  let(:user_role) { "admin" }
  let(:user_status) { "active" }
  let(:user) { FactoryBot.create(:user, role: user_role, status: user_status) }
  let(:user_headers) { build_jwt_header(generate_jwt(user.to_h)) }
end
