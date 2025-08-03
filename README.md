# Default API Template (Ruby on Rails)

A default API template with Ruby on Rails for easy bootstrapping of new projects.

## Tech Stack

* Database: `PostgreSQL`
* Rails: `8.0.2`

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

Optionally, you may run the convenience script `./bin/default_setup.sh`

## Current Features

* Uses `uuid` as primary key
* Default `user` entity with `email` as identifier.
* `rspec` for testing
