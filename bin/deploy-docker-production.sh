#!/usr/bin/env bash
set -euo pipefail

echo "Setting global safe.directory for $(pwd)"
git config --global --add safe.directory "$(pwd)"

CONTAINER_NAME="koinsapi"
DEPLOY_STAGE="${DEPLOY_STAGE:-master}"
HOST_PORT="${HOST_PORT:-3000}"
DOCKER_PORT="${DOCKER_PORT:-3000}"
BUNDLER_VERSION="2.6.2"

echo "Stopping docker container..."

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping container: ${CONTAINER_NAME} ..."
  docker stop "${CONTAINER_NAME}"
  echo "Container ${CONTAINER_NAME} stopped."
else
  echo "Container ${CONTAINER_NAME} is not running."
fi

echo "Updating codebase from ${DEPLOY_STAGE}..."

git pull origin "${DEPLOY_STAGE}"

echo "Building updated container..."

docker build \
  --build-arg BUNDLER_VERSION=${BUNDLER_VERSION} \
  -t ${CONTAINER_NAME}:latest \
  --no-cache \
  .

echo "Migrating schema to production database..."

docker run --rm \
  --name ${CONTAINER_NAME}-dbmigrate \
  --add-host=host.docker.internal:host-gateway \
  --env-file .env.production \
  ${CONTAINER_NAME}:latest \
  bash -lc 'bundle exec rails db:migrate RAILS_ENV=production'

echo "Starting container..."

# If the container exists (running or stopped), remove it
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Removing existing container: ${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}"
fi

echo "Starting ${CONTAINER_NAME} ..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  --add-host=host.docker.internal:host-gateway \
  --env-file .env.production \
  -p 127.0.0.1:${HOST_PORT}:${DOCKER_PORT} \
  ${CONTAINER_NAME}:latest

echo "Restarting nginx..."
sudo systemctl restart nginx
