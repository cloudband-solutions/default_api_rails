# Default API Template

A `Rails` default API template using PostgreSQL as the database backend.

## Environment Variables

Copy `.dotenv.env` to `.env`

* `APP_NAME`: The name of your application. Will be used in database naming convention.
* `DB_USERNAME`: Database username
* `DB_PASSWORD`: Database password
* `DB_HOST`: Host location of database
* `DB_PORT`: Port of PostgreSQL

## Creating a new project based on this template

1. Create a new project based off of `rails_template.rb`

```bash
rails new project_name --api -T -d postgresql -m https://raw.githubusercontent.com/cloudband-solutions/default_api/refs/heads/master/rails_template.rb
```

2. Copy `.dotenv.env` to `.env` and change variables accordingly.

3. Run the usual setup:

```bash
bundle install
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rspec spec
```
