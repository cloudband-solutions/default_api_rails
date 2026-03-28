# Default API Template (Ruby on Rails)

A default API template with Ruby on Rails for easy bootstrapping of new projects.

## Tech Stack

* Database: `PostgreSQL`
* Rails: `8.0.2`

## Environment Variables

For local development, copy `.dotenv.env` to `.env`.

For production deployments, copy `.dotenv.env` to `.env.production`. `docker-compose.yml` is already configured to load `.env.production` for the `app` service.

* `APP_NAME`: The name of your application. Will be used in database naming convention.
* `DB_USERNAME`: Database username
* `DB_PASSWORD`: Database password
* `DB_HOST`: Host location of database
* `DB_PORT`: Port of PostgreSQL
* `SECRET_KEY_BASE`: Required in production
* `RAILS_ENV`: Set to `production` in `.env.production`

## Production Deployment

1. Create the production environment file:

```bash
cp .dotenv.env .env.production
```

2. Update `.env.production` with your production values. At minimum, set:

```bash
APP_NAME=your_app_name
DB_USERNAME=your_db_username
DB_PASSWORD=your_db_password
DB_HOST=your_db_host
DB_PORT=5432
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_base
```

3. Build the production image:

```bash
docker compose build app
```

4. Create the production databases via Docker:

```bash
docker compose run --rm -e RAILS_ENV=production app bundle exec rails db:create
```

5. Run production migrations via Docker:

```bash
docker compose run --rm -e RAILS_ENV=production app bundle exec rails db:migrate
```

6. Start the application:

```bash
docker compose up -d app
```

## Creating a new project based on this template

1. Create a new project based off of `rails_template.rb`

```bash
rails new new_project --api -T -d postgresql -m https://raw.githubusercontent.com/cloudband-solutions/default_api_rails/master/rails_template.rb
```

2. Copy `.dotenv.env` to `.env` and change variables accordingly.

3. Run the usual local setup:

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

## Other Commands

**Fix Collation**

```bash
bundle exec rake db:refresh_collation_concurrent
```
