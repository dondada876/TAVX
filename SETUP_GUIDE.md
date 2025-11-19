# TAV-X Development Environment Setup Guide

## Quick Start

Get the TAV-X platform running locally in under 10 minutes.

### Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js 20+** ([Download](https://nodejs.org/))
- **Docker Desktop** ([Download](https://www.docker.com/products/docker-desktop))
- **Git** ([Download](https://git-scm.com/))
- **VS Code** (recommended) ([Download](https://code.visualstudio.com/))

### Automated Setup

```bash
# Clone the repository
git clone https://github.com/your-org/TAVX.git
cd TAVX

# Run the automated setup script
./infrastructure/scripts/setup-dev.sh
```

The script will:
1. ✅ Check prerequisites
2. ✅ Create .env file from template
3. ✅ Start all Docker services
4. ✅ Install dependencies for all microservices
5. ✅ Display service URLs and next steps

### Manual Setup

If you prefer to set up manually:

#### 1. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your API keys
nano .env  # or use your preferred editor
```

Required API keys (see [API Keys Section](#obtaining-api-keys)):
- Tesla API credentials
- Vapi API key
- Twilio credentials
- Stripe API keys
- Google Maps API key
- AWS credentials (for S3, Rekognition)

#### 2. Start Infrastructure Services

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

#### 3. Install Dependencies

```bash
# Install shared dependencies
cd services/shared && npm install && cd ../..

# Install dependencies for each service
cd services/auth-service && npm install && cd ../..
cd services/booking-service && npm install && cd ../..
cd services/vehicle-service && npm install && cd ../..
cd services/tour-service && npm install && cd ../..
cd services/payment-service && npm install && cd ../..
cd services/voice-service && npm install && cd ../..
cd services/notification-service && npm install && cd ../..
cd services/analytics-service && npm install && cd ../..
cd services/inspection-service && npm install && cd ../..
```

#### 4. Database Setup

```bash
# Run migrations for each service
cd services/auth-service
npm run db:generate
npm run db:migrate
npm run db:seed  # Optional: seed with test data

# Repeat for other services with databases
cd ../booking-service
npm run db:migrate

# etc...
```

#### 5. Start Development Servers

Option 1: Start services individually
```bash
# Terminal 1: Auth Service
cd services/auth-service && npm run dev

# Terminal 2: Booking Service
cd services/booking-service && npm run dev

# Terminal 3: Vehicle Service
cd services/vehicle-service && npm run dev

# ... continue for other services
```

Option 2: Use a process manager (recommended)
```bash
# Install PM2 globally
npm install -g pm2

# Start all services
pm2 start ecosystem.config.js

# View logs
pm2 logs

# Stop all
pm2 stop all
```

---

## Service URLs

After setup, the following services will be available:

### Core Infrastructure
- **PostgreSQL**: `localhost:5432`
  - Database: `tavx_db`
  - User: `tavx_user`
  - Password: See `.env`

- **Redis**: `localhost:6379`
  - Password: See `.env`

- **RabbitMQ**:
  - AMQP: `localhost:5672`
  - Management UI: http://localhost:15672
  - User: `tavx`
  - Password: See `.env`

- **Qdrant**: http://localhost:6333
  - API Key: See `.env`

### API Gateway
- **Kong Proxy**: http://localhost:8000
- **Kong Admin**: http://localhost:8001

### Monitoring
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000
  - Username: `admin`
  - Password: See `.env`

### Development Tools (Optional)

Start optional tools with:
```bash
docker-compose --profile tools up -d
```

- **pgAdmin**: http://localhost:5050
  - Email: `admin@tavx.com`
  - Password: See `.env`

- **Redis Commander**: http://localhost:8081

---

## Obtaining API Keys

### Tesla API
1. Visit https://developer.tesla.com
2. Register for Fleet API access
3. Create application
4. Note `CLIENT_ID` and `CLIENT_SECRET`
5. Use OAuth flow to obtain access/refresh tokens

### Vapi (Voice AI)
1. Sign up at https://vapi.ai
2. Create account
3. Navigate to API Keys
4. Copy API key to `.env`

### Twilio (SMS/MMS)
1. Sign up at https://twilio.com
2. Get Account SID and Auth Token from dashboard
3. Purchase a phone number
4. Copy credentials to `.env`

### Stripe (Payments)
1. Sign up at https://stripe.com
2. Get API keys from Developers > API Keys
3. Use test mode keys for development
4. Copy to `.env`

### Google Maps API
1. Go to https://console.cloud.google.com
2. Create new project
3. Enable APIs: Maps JavaScript API, Geocoding API, Directions API
4. Create API key
5. Copy to `.env`

### AWS (S3, Rekognition)
1. Create AWS account at https://aws.amazon.com
2. Create IAM user with programmatic access
3. Attach policies: `AmazonS3FullAccess`, `AmazonRekognitionFullAccess`
4. Note Access Key ID and Secret Access Key
5. Copy to `.env`

### VoiceMap (Optional - Tours)
1. Sign up at https://voicemap.me/publisher
2. Get Publisher API key
3. Copy to `.env`

---

## Troubleshooting

### Docker containers won't start

**Issue**: Port already in use
```bash
# Find process using port
lsof -i :5432  # Replace with your port

# Kill process or change port in docker-compose.yml
```

**Issue**: Docker out of disk space
```bash
# Clean up Docker
docker system prune -a --volumes
```

### Database connection errors

**Issue**: Connection refused
```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres

# Restart service
docker-compose restart postgres
```

**Issue**: Authentication failed
```bash
# Verify credentials in .env match docker-compose.yml
# Restart services after changing .env
docker-compose down && docker-compose up -d
```

### npm install fails

**Issue**: Permission errors
```bash
# Fix npm permissions (macOS/Linux)
sudo chown -R $(whoami) ~/.npm
```

**Issue**: Network timeout
```bash
# Use a different registry
npm config set registry https://registry.npmjs.org/

# Clear cache
npm cache clean --force
```

### Service won't start

**Issue**: Port already in use
```bash
# Check package.json for port number
# Find and kill process using that port
lsof -i :3001  # Replace with service port
kill -9 <PID>
```

**Issue**: Environment variables not loaded
```bash
# Ensure .env is in root directory
# Restart service
cd services/auth-service
npm run dev
```

---

## Development Workflow

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Edit code
   - Services will hot-reload automatically

3. **Test your changes**
   ```bash
   # Run unit tests
   npm test

   # Run integration tests
   npm run test:integration

   # Run linter
   npm run lint
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   git push origin feature/your-feature-name
   ```

### Running Tests

```bash
# Unit tests (fast)
npm test

# Watch mode (for development)
npm run test:watch

# Integration tests (slower, requires services running)
npm run test:integration

# Coverage report
npm run test:coverage
```

### Debugging

#### VS Code Launch Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Auth Service",
      "cwd": "${workspaceFolder}/services/auth-service",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "console": "integratedTerminal",
      "skipFiles": ["<node_internals>/**"]
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Booking Service",
      "cwd": "${workspaceFolder}/services/booking-service",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "console": "integratedTerminal"
    }
  ]
}
```

#### Using Chrome DevTools

```bash
# Start service with inspect flag
node --inspect-brk dist/index.js

# Open chrome://inspect in Chrome
# Click "Inspect" under your Node process
```

---

## Common Tasks

### Reset Database

```bash
# Drop and recreate database
docker-compose down -v
docker-compose up -d postgres
cd services/auth-service
npm run db:migrate
npm run db:seed
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f postgres

# Application logs
cd services/auth-service
npm run dev  # Logs appear in terminal
```

### Update Dependencies

```bash
# Check for outdated packages
npm outdated

# Update all packages
npm update

# Update specific package
npm install package-name@latest
```

### Clean Install

```bash
# Remove all node_modules
find . -name "node_modules" -type d -prune -exec rm -rf '{}' +

# Remove package-lock files
find . -name "package-lock.json" -type f -delete

# Reinstall
./infrastructure/scripts/setup-dev.sh
```

---

## VS Code Recommended Extensions

Install these extensions for the best development experience:

```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "prisma.prisma",
    "ms-azuretools.vscode-docker",
    "eamodio.gitlens",
    "humao.rest-client",
    "ms-vscode.vscode-typescript-next",
    "orta.vscode-jest",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

Create `.vscode/extensions.json` with the above content.

### Extension Usage

- **ESLint**: Auto-fix on save
- **Prettier**: Format on save
- **Prisma**: Schema syntax highlighting and formatting
- **Docker**: Manage containers from VS Code
- **GitLens**: Enhanced Git integration
- **REST Client**: Test API endpoints (create `.http` files)

---

## Environment Variables Reference

See `.env.example` for complete list. Key variables:

### Application
- `NODE_ENV`: `development` | `staging` | `production`
- `APP_NAME`: `TAV-X`
- `APP_URL`: Your application URL

### Database
- `POSTGRES_HOST`: PostgreSQL host
- `POSTGRES_PORT`: PostgreSQL port (default: 5432)
- `POSTGRES_DB`: Database name
- `POSTGRES_USER`: Database user
- `POSTGRES_PASSWORD`: Database password
- `REDIS_HOST`: Redis host
- `REDIS_PORT`: Redis port (default: 6379)
- `REDIS_PASSWORD`: Redis password

### Authentication
- `JWT_SECRET`: Secret for JWT signing (min 32 chars)
- `JWT_EXPIRES_IN`: Token expiry (default: 15m)
- `REFRESH_TOKEN_SECRET`: Refresh token secret
- `REFRESH_TOKEN_EXPIRES_IN`: Refresh expiry (default: 7d)

### Third-Party APIs
- `TESLA_CLIENT_ID`: Tesla API client ID
- `TESLA_CLIENT_SECRET`: Tesla API secret
- `VAPI_API_KEY`: Vapi voice AI key
- `TWILIO_ACCOUNT_SID`: Twilio account SID
- `TWILIO_AUTH_TOKEN`: Twilio auth token
- `STRIPE_SECRET_KEY`: Stripe secret key
- `GOOGLE_MAPS_API_KEY`: Google Maps key
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

---

## Next Steps

After completing setup:

1. **Explore the codebase**
   - Review `TECH_STACK.md` for technology decisions
   - Read `docs/architecture/` for system design
   - Check `docs/prd/` for product requirements

2. **Set up your first feature**
   - Pick a user story from the PRD
   - Create a feature branch
   - Implement and test
   - Submit a pull request

3. **Join the team chat**
   - Connect with the team on Slack
   - Ask questions in #engineering
   - Share your progress

4. **Review documentation**
   - API documentation: http://localhost:8000/api-docs
   - Database schema: Check Prisma schema files
   - Event bus: See `shared/message-queue/Events.ts`

---

## Getting Help

- **Documentation**: See `docs/` directory
- **Issues**: Check GitHub Issues
- **Team Chat**: Slack #engineering channel
- **Email**: dev@tavx.com

---

## Teardown

To completely remove the development environment:

```bash
./infrastructure/scripts/teardown-dev.sh
```

This will:
- Stop all Docker containers
- Optionally remove volumes (deletes data)
- Clean up resources

---

**Happy coding! 🚀**
