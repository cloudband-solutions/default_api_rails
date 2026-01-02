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

## AWS SSM environment generation

`bin/generate_env_from_aws_ssm.sh` pulls Rails and database secrets out of AWS Systems Manager (SSM) under `/koins/<stage>` and writes a `.env.<rails_env>` file that Rails can consume.

### What it does

* Resolves `STAGE` via `--stage` (default: `dev`, with `prod` mapping `RAILS_ENV=production`), writes the file `.env.development` / `.env.production`, and refuses to run against `prod` in CI.
* Fetches `/koins/<stage>/db/main/{username,password,host,name}` and `/koins/<stage>/rails/secret_key_base` using `aws ssm get-parameter`.
* Emits runtime defaults for Rails, bundler, AWS, and the database; validates that variables like `RAILS_ENV`, `SECRET_KEY_BASE`, `DATABASE_*`, and `DATABASE_PORT` appear in the generated file.
* Sources the generated file (`set -a; source .env.<rails_env>; set +a`) so the current shell inherits all values.

### Requirements

* `aws` CLI configured with access to the target SSM path.
* `sed` (the script verifies its presence before running).
* Optional overrides:
  * `AWS_REGION` (defaults to `ap-southeast-1`).
  * `BASE_URL`, `EMAIL_SENDER`, `AWS_BUCKET`, `AWS_SQS_REPORT_QUEUE` for application-specific settings. These are interpolated into the `.env.<rails_env>` file exactly as exported in the environment before the script runs.

### Usage

```bash
./bin/generate_env_from_aws_ssm.sh --stage staging
```

Set the stage you want to target; the script maps `STAGE=prod` to `RAILS_ENV=production` (keeping `STAGE=dev`/`staging` etc. as-is). After it finishes, `.env.<rails_env>` is ready for the Rails process and for local tooling that reads dotenv files.

## Creating a new project based on this template

1. Create a new project based off of `rails_template.rb`

```bash
rails new new_project --api -T -d postgresql -m https://raw.githubusercontent.com/cloudband-solutions/default_api_rails/master/rails_template.rb
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

## Other Commands

**Fix Collation**

```bash
bundle exec rake db:refresh_collation_concurrent
```
