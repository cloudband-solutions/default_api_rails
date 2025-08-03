include ApiHelpers

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    encrypted_password { generate_password_hash("password") }
    status { "pending" }
  end

  factory :active_user, class: 'User' do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    encrypted_password { generate_password_hash("password") }
    status { "active" }
  end

  factory :inactive_user, class: 'User' do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    encrypted_password { generate_password_hash("password") }
    status { "inactive" }
  end
end
