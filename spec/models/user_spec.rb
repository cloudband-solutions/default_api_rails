require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'defaults role to user for new records' do
      user = FactoryBot.create(:user, role: nil)

      expect(user.role).to eq("user")
    end
  end

  describe '#soft_delete!' do
    it 'marks the user as deleted and rewrites the email' do
      user = FactoryBot.create(:user, :admin)
      original_email = user.email

      user.soft_delete!

      expect(user.reload.status).to eq('deleted')
      expect(user).to be_deleted
      expect(user.email).to match(/\Adeleted-.+-#{Regexp.escape(original_email)}\z/)
    end
  end
end
