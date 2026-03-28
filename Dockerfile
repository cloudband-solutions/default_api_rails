# Use ruby version
FROM ruby:3.4-slim

# Install essentials
# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    git \
    tzdata \
    libvips \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

# Create necessary folders
RUN mkdir -p tmp/pids

# Install the specified Bundler version
RUN gem install bundler -v "$BUNDLER_VERSION"

# Set app directory
WORKDIR /app

# Copy Gemfiles before copying the rest of the code (to leverage Docker cache)
COPY Gemfile Gemfile.lock ./

# Install production gems only
RUN bundle config set without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy the rest of the application code
COPY . .

# Expose the default port (can be overridden)
EXPOSE $PORT

# Start Puma using your puma.rb config
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
