#!/bin/bash

# Local deployment script for Chatwoot
# Similar to Hi.Events deploy-local.sh

set -e

echo "🚀 Starting local Chatwoot deployment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build the Docker image
echo "🔨 Building Chatwoot Docker image..."
docker build \
    --build-arg RAILS_ENV=production \
    --build-arg NODE_ENV=production \
    --build-arg NODE_OPTIONS=--max-old-space-size=4096 \
    -f docker/Dockerfile \
    -t chatwoot:latest .

# Create local docker-compose file
echo "📄 Creating local docker-compose configuration..."
cat > docker-compose.local.yml << EOF
version: '3.8'

services:
  rails:
    image: chatwoot:latest
    container_name: chatwoot-rails-local
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - NODE_ENV=production
      - INSTALLATION_ENV=docker
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/chatwoot
      - REDIS_URL=redis://redis:6379/0
      - SECRET_KEY_BASE=local-secret-key-base-for-development-only
      - FRONTEND_URL=http://localhost:3000
      - RAILS_LOG_TO_STDOUT=true
      - USE_INBOX_AVATAR_FOR_BOT=true
      - MAILER_SENDER_EMAIL=chat@localhost
    volumes:
      - chatwoot_storage:/app/storage
      - chatwoot_public:/app/public
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    entrypoint: docker/entrypoints/rails.sh
    command: ['bundle', 'exec', 'rails', 's', '-p', '3000', '-b', '0.0.0.0']
    networks:
      - chatwoot-local

  sidekiq:
    image: chatwoot:latest
    container_name: chatwoot-sidekiq-local
    restart: unless-stopped
    environment:
      - RAILS_ENV=production
      - NODE_ENV=production
      - INSTALLATION_ENV=docker
      - DATABASE_URL=postgresql://postgres:password@postgres:5432/chatwoot
      - REDIS_URL=redis://redis:6379/0
      - SECRET_KEY_BASE=local-secret-key-base-for-development-only
      - FRONTEND_URL=http://localhost:3000
      - RAILS_LOG_TO_STDOUT=true
      - USE_INBOX_AVATAR_FOR_BOT=true
      - MAILER_SENDER_EMAIL=chat@localhost
    volumes:
      - chatwoot_storage:/app/storage
      - chatwoot_public:/app/public
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: ['bundle', 'exec', 'sidekiq', '-C', 'config/sidekiq.yml']
    networks:
      - chatwoot-local

  redis:
    image: redis:7-alpine
    container_name: chatwoot-redis-local
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - chatwoot_redis_local:/data
    networks:
      - chatwoot-local
    healthcheck:
      test: [ "CMD", "redis-cli", "ping" ]
      interval: 10s
      timeout: 5s
      retries: 5

  postgres:
    image: pgvector/pgvector:pg16
    container_name: chatwoot-postgres-local
    restart: unless-stopped
    environment:
      POSTGRES_DB: chatwoot
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - chatwoot_postgres_local:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - chatwoot-local
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U postgres" ]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  chatwoot-local:
    driver: bridge

volumes:
  chatwoot_postgres_local:
    driver: local
  chatwoot_redis_local:
    driver: local
  chatwoot_storage:
    driver: local
  chatwoot_public:
    driver: local
EOF

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.local.yml down --remove-orphans 2>/dev/null || true

# Start the services
echo "▶️  Starting Chatwoot services..."
docker-compose -f docker-compose.local.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Run database setup
echo "🔄 Setting up database..."
docker-compose -f docker-compose.local.yml exec -T rails bundle exec rails db:create || true
docker-compose -f docker-compose.local.yml exec -T rails bundle exec rails db:migrate

# Run seeds
echo "🌱 Running database seeds..."
docker-compose -f docker-compose.local.yml exec -T rails bundle exec rails db:seed || true

# Precompile assets
echo "🎨 Precompiling assets..."
docker-compose -f docker-compose.local.yml exec -T rails bundle exec rails assets:precompile || true

# Health check
echo "🔍 Performing health check..."
sleep 10

if curl -f -s -o /dev/null http://localhost:3000; then
    echo "✅ Chatwoot is running successfully!"
    echo "🌐 Access your application at: http://localhost:3000"
    echo ""
    echo "📋 Service status:"
    docker-compose -f docker-compose.local.yml ps
    echo ""
    echo "📝 To view logs: docker-compose -f docker-compose.local.yml logs -f"
    echo "🛑 To stop: docker-compose -f docker-compose.local.yml down"
else
    echo "⚠️  Application might not be fully ready yet"
    echo "📋 Recent logs:"
    docker-compose -f docker-compose.local.yml logs --tail=20 rails
fi

echo "🏁 Local deployment completed!"
