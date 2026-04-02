# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

password_helper = Object.new.extend(ApiHelpers)

User.find_or_create_by!(email: "admin@example.com") do |user|
  user.first_name = "Admin"
  user.last_name = "User"
  user.role = "admin"
  user.status = "active"
  user.encrypted_password = password_helper.generate_password_hash("password")
end
