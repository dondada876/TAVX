#!/bin/bash

# TAV-X Development Environment Setup Script
# This script sets up the complete local development environment

set -e

echo "🚀 TAV-X Development Environment Setup"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker is not installed. Please install Docker Desktop.${NC}" >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo -e "${RED}❌ Node.js is not installed. Please install Node.js 20+.${NC}" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo -e "${RED}❌ Git is not installed.${NC}" >&2; exit 1; }

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# Check Node version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
    echo -e "${YELLOW}⚠️  Warning: Node.js 20+ is recommended. You have version $(node -v)${NC}"
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created. Please edit it with your API keys.${NC}"
else
    echo -e "${YELLOW}⚠️  .env file already exists. Skipping creation.${NC}"
fi
echo ""

# Start Docker containers
echo "🐳 Starting Docker containers..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🏥 Checking service health..."
docker-compose ps

echo ""
echo "📦 Installing dependencies for all services..."
echo ""

# Install shared dependencies
if [ -d "services/shared" ]; then
    echo "Installing shared dependencies..."
    cd services/shared && npm install && cd ../..
fi

# Install dependencies for each service
for service in services/*/; do
    if [ -f "${service}package.json" ] && [ "$service" != "services/shared/" ]; then
        service_name=$(basename "$service")
        echo "Installing dependencies for $service_name..."
        cd "$service" && npm install && cd ../..
    fi
done

echo ""
echo -e "${GREEN}✅ All dependencies installed${NC}"
echo ""

# Initialize databases
echo "🗄️  Initializing databases..."
echo "Note: Run 'npm run db:migrate' in each service directory to set up schemas"
echo ""

# Print access information
echo "======================================"
echo "🎉 Setup complete!"
echo "======================================"
echo ""
echo "📍 Service URLs:"
echo "   - PostgreSQL:      localhost:5432"
echo "   - Redis:           localhost:6379"
echo "   - RabbitMQ UI:     http://localhost:15672 (user: tavx)"
echo "   - Qdrant:          http://localhost:6333"
echo "   - Kong Admin:      http://localhost:8001"
echo "   - Kong Proxy:      http://localhost:8000"
echo "   - Prometheus:      http://localhost:9090"
echo "   - Grafana:         http://localhost:3000 (admin:admin)"
echo ""
echo "🔧 Optional Tools (run: docker-compose --profile tools up -d):"
echo "   - pgAdmin:         http://localhost:5050"
echo "   - Redis Commander: http://localhost:8081"
echo ""
echo "🏃 Next Steps:"
echo "   1. Edit .env file with your API keys"
echo "   2. Run database migrations: cd services/[service] && npm run db:migrate"
echo "   3. Start services: cd services/[service] && npm run dev"
echo ""
echo "📚 Documentation:"
echo "   - README.md"
echo "   - TECH_STACK.md"
echo "   - docs/Implementation_Summary.md"
echo ""
