source "https://rubygems.org"

gem "rails"
gem "pg"
gem "puma"
gem "bcrypt"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "kamal", require: false
gem "jwt"
gem "thruster", require: false
gem "rack-cors"
gem "dotenv-rails"
gem "kaminari"

group :test do
  gem "rspec-rails"
end

group :development, :test do
  gem "factory_bot_rails"
  gem "faker"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end
