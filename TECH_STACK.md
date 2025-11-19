# TAV-X Complete Technology Stack
## Build-Ready Technical Specifications

**Version:** 1.0
**Date:** November 19, 2025
**Status:** Ready for Implementation

---

## Executive Summary

This document provides the complete, build-ready technology stack for the TAV-X Tesla Autonomous Tour & Rental Platform. All recommendations are based on:

- **Development velocity** (MVP launch in 3 months)
- **Cost optimization** (target: <$30K/year infrastructure)
- **Scalability** (1-100 vehicles, 1000+ bookings/month)
- **Maintainability** (small team, offshore VAs)
- **Integration requirements** (Tesla API, Vapi, Stripe, Twilio, VoiceMap)

---

## Table of Contents

1. [Backend Services](#1-backend-services)
2. [Frontend Applications](#2-frontend-applications)
3. [Data Layer](#3-data-layer)
4. [Infrastructure & DevOps](#4-infrastructure--devops)
5. [Third-Party Services](#5-third-party-services)
6. [Development Tools](#6-development-tools)
7. [Cost Analysis](#7-cost-analysis)
8. [Implementation Phases](#8-implementation-phases)
9. [Alternative Considerations](#9-alternative-considerations)

---

## 1. Backend Services

### 1.1 Runtime & Framework

**Selected Stack:**
```yaml
Runtime: Node.js v20 LTS
Language: TypeScript 5.3+
Framework: Express.js 4.18+
Alternative: Fastify (for performance-critical services)
```

**Justification:**
- ✅ Node.js 20 LTS provides stability through April 2026
- ✅ TypeScript ensures type safety and better developer experience
- ✅ Express.js is battle-tested with extensive middleware ecosystem
- ✅ Team familiarity and abundant talent pool
- ✅ Excellent async I/O performance for real-time vehicle tracking

**Key Dependencies:**
```json
{
  "express": "^4.18.2",
  "typescript": "^5.3.0",
  "ts-node": "^10.9.2",
  "@types/node": "^20.10.0",
  "@types/express": "^4.17.21",
  "dotenv": "^16.3.1",
  "helmet": "^7.1.0",
  "cors": "^2.8.5",
  "compression": "^1.7.4",
  "morgan": "^1.10.0"
}
```

### 1.2 Microservices Architecture

**Services Breakdown:**

```
┌─────────────────────────────────────────────────────┐
│              MICROSERVICES ECOSYSTEM                │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. auth-service        (Port 3001)                │
│     - User authentication & authorization          │
│     - JWT token management                         │
│     - Role-based access control                    │
│                                                     │
│  2. booking-service     (Port 3002)                │
│     - Reservation management                       │
│     - Availability checks                          │
│     - Booking lifecycle                            │
│                                                     │
│  3. vehicle-service     (Port 3003)                │
│     - Tesla API integration                        │
│     - Vehicle control (lock/unlock)                │
│     - Real-time telemetry                          │
│     - Status tracking                              │
│                                                     │
│  4. tour-service        (Port 3004)                │
│     - Tour content management                      │
│     - GPS tracking                                 │
│     - Waypoint triggers                            │
│     - Session analytics                            │
│                                                     │
│  5. payment-service     (Port 3005)                │
│     - Stripe integration                           │
│     - Payment processing                           │
│     - Revenue split calculations                   │
│     - Refunds & disputes                           │
│                                                     │
│  6. voice-service       (Port 3006)                │
│     - Vapi webhook handlers                        │
│     - Check-in/check-out logic                     │
│     - Conversation logging                         │
│     - Photo upload processing                      │
│                                                     │
│  7. notification-service (Port 3007)               │
│     - SMS via Twilio                               │
│     - Email via SendGrid                           │
│     - Slack alerts                                 │
│     - Push notifications                           │
│                                                     │
│  8. analytics-service   (Port 3008)                │
│     - Event aggregation                            │
│     - Reporting                                    │
│     - Partner dashboards                           │
│     - Business intelligence                        │
│                                                     │
│  9. inspection-service  (Port 3009)                │
│     - Photo storage (S3)                           │
│     - Computer vision (AWS Rekognition)            │
│     - Damage detection                             │
│     - Comparison logic                             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 1.3 API Gateway

**Selected: Kong Gateway (Open Source)**

```yaml
Version: Kong Gateway 3.4+
Mode: DB-backed (PostgreSQL)
Plugins:
  - Rate Limiting
  - JWT Authentication
  - CORS
  - Request/Response Logging
  - Prometheus Metrics
  - IP Restriction
```

**Configuration:**
```yaml
# kong.yml
_format_version: "3.0"

services:
  - name: booking-service
    url: http://booking-service:3002
    routes:
      - name: booking-routes
        paths:
          - /api/v1/bookings
        methods: [GET, POST, PUT, DELETE]
        strip_path: false
    plugins:
      - name: rate-limiting
        config:
          minute: 60
          hour: 1000
      - name: jwt
      - name: cors

  - name: vehicle-service
    url: http://vehicle-service:3003
    routes:
      - name: vehicle-routes
        paths:
          - /api/v1/vehicles
        strip_path: false
    plugins:
      - name: jwt
      - name: rate-limiting
        config:
          minute: 30

  - name: webhook-routes
    url: http://voice-service:3006
    routes:
      - name: webhooks
        paths:
          - /webhooks/*
        strip_path: false
    plugins:
      - name: rate-limiting
        config:
          minute: 100
```

**Alternative:** Traefik (simpler, good for Kubernetes)

### 1.4 Message Queue & Event Bus

**Selected: RabbitMQ 3.12+**

```yaml
Deployment: Docker container
Management UI: Enabled on port 15672
Exchange Type: Topic
Queues:
  - booking.events
  - vehicle.events
  - tour.events
  - payment.events
  - notifications.events
Plugins:
  - rabbitmq_management
  - rabbitmq_prometheus
```

**Event Patterns:**
```typescript
// Event structure
interface Event {
  type: string;
  timestamp: Date;
  source: string;
  data: Record<string, any>;
  correlationId: string;
}

// Example events
Events.BOOKING_CREATED
Events.BOOKING_CONFIRMED
Events.CHECKIN_STARTED
Events.CHECKIN_COMPLETED
Events.VEHICLE_UNLOCKED
Events.TOUR_STARTED
Events.TOUR_WAYPOINT_REACHED
Events.PAYMENT_SUCCESS
Events.NOTIFICATION_SENT
```

**Alternative:** AWS SQS + SNS (for AWS-native deployment)

---

## 2. Frontend Applications

### 2.1 Customer Booking Portal

**Selected: WordPress + WooCommerce**

```yaml
WordPress: 6.4+
PHP: 8.2+
Theme: Custom theme based on Astra Pro
Plugins:
  - WooCommerce 8.3+
  - Amelia Booking 1.0+
  - WPForms (contact forms)
  - Yoast SEO
  - WP Rocket (caching)
  - Wordfence (security)
Custom Plugin: TAVX Booking Integration
```

**Justification:**
- ✅ Familiar platform for non-technical team members
- ✅ Extensive plugin ecosystem
- ✅ Built-in payment processing via WooCommerce
- ✅ SEO-optimized out of the box
- ✅ Low development cost ($5-10K for custom theme + plugin)

**Custom Plugin Features:**
```php
// tavx-booking/tavx-booking.php
/*
Plugin Name: TAVX Booking Integration
Version: 1.0.0
Description: Custom Tesla rental booking integration
*/

Features:
- Real-time vehicle availability API integration
- Dynamic pricing based on demand
- Tour package selection
- Custom booking confirmation emails
- Webhook to backend API for booking sync
```

### 2.2 Operations Dashboard

**Phase 1 (MVP): Retool**
```yaml
Plan: Business ($50/user/month)
Users: 3-5 (staff members)
Features:
  - Fleet status map
  - Active rentals list
  - Maintenance queue
  - Revenue analytics
  - Partner management
Integration: Direct PostgreSQL + REST API
```

**Phase 2 (Production): Custom React Dashboard**
```yaml
Framework: React 18+ with Vite
UI Library: shadcn/ui + Tailwind CSS
State Management: Zustand
Data Fetching: TanStack Query (React Query)
Real-time: Socket.io client
Maps: Mapbox GL JS
Charts: Recharts
```

**Key Dependencies:**
```json
{
  "react": "^18.2.0",
  "vite": "^5.0.0",
  "tailwindcss": "^3.4.0",
  "@tanstack/react-query": "^5.12.0",
  "zustand": "^4.4.7",
  "socket.io-client": "^4.6.0",
  "mapbox-gl": "^3.0.0",
  "recharts": "^2.10.0",
  "react-router-dom": "^6.20.0",
  "axios": "^1.6.2",
  "date-fns": "^2.30.0"
}
```

### 2.3 Partner Portal

**Selected: React SPA**

Same tech stack as Operations Dashboard but with:
- Public-facing authentication
- Limited data access (only partner's vehicles)
- Automated PDF report generation
- Stripe Connect integration for payouts

### 2.4 Mobile Tour App (In-Vehicle Tablet)

**Selected: React Native + Expo**

```yaml
Framework: React Native 0.72+
Platform: Expo SDK 50+
Target Devices: iPad (iOS 15+), Samsung Tablets (Android 11+)
Maps: react-native-maps with Google Maps
Audio: expo-av
Location: expo-location
Storage: expo-sqlite for offline
```

**Key Dependencies:**
```json
{
  "expo": "~50.0.0",
  "react-native": "0.72.6",
  "expo-location": "~16.5.0",
  "expo-av": "~13.10.0",
  "react-native-maps": "1.7.1",
  "expo-sqlite": "~13.0.0",
  "axios": "^1.6.2",
  "@react-navigation/native": "^6.1.9",
  "@react-navigation/stack": "^6.3.20"
}
```

**Features:**
- Offline-first architecture
- Background GPS tracking
- Geofence-triggered audio playback
- Tour progress syncing
- Emergency support button
- Multi-language support

---

## 3. Data Layer

### 3.1 Primary Database

**Phase 1 (MVP): Airtable**
```yaml
Plan: Team ($20/user/month)
Users: 3
Use Cases:
  - Quick prototyping
  - No-code admin interface
  - API-first approach
  - Easy VA access
Limitations:
  - 50,000 records per base
  - 5 API requests/second
  - Not suitable for production scale
```

**Phase 2 (Production): PostgreSQL 16+**
```yaml
Version: PostgreSQL 16.1
Deployment: AWS RDS (db.t3.medium)
Storage: 100GB SSD (gp3)
Backup: Automated daily snapshots
High Availability: Multi-AZ deployment (production)
Connection Pooling: PgBouncer
```

**Schema Highlights:**
```sql
-- Core tables
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vin VARCHAR(17) UNIQUE NOT NULL,
  tesla_id VARCHAR(255) UNIQUE,
  model VARCHAR(50) NOT NULL,
  year INTEGER NOT NULL,
  color VARCHAR(50),
  fsd_enabled BOOLEAN DEFAULT false,
  owner_partner_id UUID REFERENCES partners(id),
  current_status VARCHAR(50) DEFAULT 'available',
  current_location POINT,
  current_battery_percent INTEGER,
  total_miles_driven INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  confirmation_code VARCHAR(10) UNIQUE NOT NULL,
  customer_id UUID REFERENCES customers(id),
  vehicle_id UUID REFERENCES vehicles(id),
  tour_package_id UUID REFERENCES tour_packages(id),
  pickup_datetime TIMESTAMP NOT NULL,
  return_datetime TIMESTAMP NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  total_price DECIMAL(10,2) NOT NULL,
  stripe_payment_intent_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tour_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  duration_minutes INTEGER NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  thumbnail_url TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE waypoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tour_route_id UUID REFERENCES tour_routes(id),
  sequence INTEGER NOT NULL,
  name VARCHAR(255) NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  geofence_radius_meters INTEGER DEFAULT 100,
  narration_audio_url TEXT,
  narration_text TEXT,
  narration_duration_seconds INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tour_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES bookings(id),
  tour_route_id UUID REFERENCES tour_routes(id),
  started_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP,
  gps_trace JSONB,
  waypoints_visited UUID[],
  completion_rate DECIMAL(5,2),
  rating INTEGER,
  feedback TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE inspection_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES bookings(id),
  vehicle_id UUID REFERENCES vehicles(id),
  inspection_type VARCHAR(50) NOT NULL, -- 'checkin' or 'checkout'
  inspector_name VARCHAR(255),
  odometer_reading INTEGER NOT NULL,
  battery_level INTEGER NOT NULL,
  photos TEXT[], -- Array of S3 URLs
  damage_notes TEXT,
  ai_damage_detected BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Performance indexes
CREATE INDEX idx_bookings_dates ON bookings(pickup_datetime, return_datetime) WHERE status NOT IN ('cancelled', 'completed');
CREATE INDEX idx_bookings_vehicle ON bookings(vehicle_id, pickup_datetime, return_datetime);
CREATE INDEX idx_vehicles_status ON vehicles(current_status) WHERE current_status = 'available';
CREATE INDEX idx_waypoints_location ON waypoints USING GIST (point(longitude, latitude));
```

**ORM: Prisma 5.7+**
```yaml
Why Prisma:
  - Type-safe database access
  - Automatic migrations
  - Intuitive query builder
  - Great TypeScript support
Alternative: TypeORM (more mature, more complex)
```

### 3.2 Caching Layer

**Selected: Redis 7.2+**

```yaml
Deployment: AWS ElastiCache (cache.t3.micro)
Use Cases:
  - Session storage
  - API response caching
  - Rate limiting counters
  - Vehicle availability cache
  - Real-time data pub/sub
Eviction Policy: allkeys-lru
Max Memory: 512MB (MVP) → 2GB (Production)
```

**Caching Strategy:**
```typescript
// Example: Vehicle availability caching
const CACHE_TTL = {
  AVAILABILITY: 60, // 1 minute
  VEHICLE_STATUS: 30, // 30 seconds
  TOUR_CONTENT: 3600, // 1 hour
  USER_SESSION: 86400 // 24 hours
};

// Cache key patterns
const keys = {
  availability: (startDate: string, endDate: string) =>
    `availability:${startDate}:${endDate}`,
  vehicleStatus: (vehicleId: string) =>
    `vehicle:${vehicleId}:status`,
  tourRoute: (tourId: string) =>
    `tour:${tourId}:route`
};
```

### 3.3 Vector Database

**Selected: Qdrant 1.7+**

```yaml
Deployment: Qdrant Cloud (1GB Free tier → Paid as needed)
Use Cases:
  - Voice conversation history search
  - Tour content semantic search
  - Customer support query matching
  - Historical context retrieval
Vector Size: 1536 (OpenAI embeddings)
Similarity Metric: Cosine
```

**Schema:**
```python
# Conversation history collection
{
  "collection_name": "voice_conversations",
  "vectors": {
    "size": 1536,
    "distance": "Cosine"
  },
  "payload_schema": {
    "booking_id": "keyword",
    "call_id": "keyword",
    "timestamp": "datetime",
    "conversation_text": "text",
    "sentiment": "keyword",
    "issues_detected": "keyword[]"
  }
}
```

### 3.4 File Storage

**Selected: AWS S3**

```yaml
Bucket Structure:
  tavx-vehicle-photos/
    - checkin/{booking_id}/{timestamp}_{photo_number}.jpg
    - checkout/{booking_id}/{timestamp}_{photo_number}.jpg
  tavx-tour-audio/
    - {tour_route_id}/{waypoint_id}/{language}.mp3
  tavx-profile-images/
    - users/{user_id}.jpg
  tavx-backups/
    - database/{date}.sql.gz
    - logs/{date}.log.gz

Lifecycle Policies:
  - vehicle-photos: Move to Glacier after 1 year
  - tour-audio: Keep in Standard (frequent access)
  - backups: Intelligent-Tiering

CDN: CloudFront for tour audio delivery
```

---

## 4. Infrastructure & DevOps

### 4.1 Cloud Provider

**Selected: AWS (Amazon Web Services)**

**Justification:**
- ✅ Most comprehensive service offering
- ✅ Best support for all third-party integrations
- ✅ Mature Kubernetes support (EKS)
- ✅ Generous free tier for MVP
- ✅ Excellent documentation and community

**Services Used:**
```yaml
Compute:
  - EKS (Elastic Kubernetes Service) for microservices
  - EC2 (for Kong, RabbitMQ during MVP)
  - Lambda (for serverless functions like image processing)

Storage:
  - S3 (file storage)
  - EBS (persistent volumes)

Database:
  - RDS PostgreSQL (primary database)
  - ElastiCache Redis (caching)

Networking:
  - VPC (isolated network)
  - ALB (Application Load Balancer)
  - Route 53 (DNS)
  - CloudFront (CDN)

Security:
  - IAM (access management)
  - Secrets Manager (API keys, tokens)
  - WAF (web application firewall)
  - Shield (DDoS protection)

Monitoring:
  - CloudWatch (logs and metrics)

AI/ML:
  - Rekognition (damage detection from photos)
```

### 4.2 Container Orchestration

**Phase 1 (MVP): Docker Compose**
```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    ports: ['5432:5432']
    environment:
      POSTGRES_DB: tavx_db
      POSTGRES_USER: tavx_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports: ['6379:6379']
    command: redis-server --requirepass ${REDIS_PASSWORD}

  rabbitmq:
    image: rabbitmq:3.12-management-alpine
    ports:
      - '5672:5672'
      - '15672:15672'
    environment:
      RABBITMQ_DEFAULT_USER: tavx
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}

  kong:
    image: kong:3.4-alpine
    ports:
      - '8000:8000'
      - '8001:8001'
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: postgres
      KONG_PG_USER: kong
      KONG_PG_PASSWORD: ${KONG_DB_PASSWORD}

  qdrant:
    image: qdrant/qdrant:v1.7.0
    ports: ['6333:6333']
    volumes:
      - qdrant_data:/qdrant/storage

volumes:
  postgres_data:
  qdrant_data:
```

**Phase 2 (Production): Kubernetes (EKS)**
```yaml
Cluster Configuration:
  Node Group: 3x t3.medium (2 vCPU, 4GB RAM each)
  Auto-scaling: 3-10 nodes based on load
  Namespace: tavx-prod

Key Resources:
  - Deployments (one per microservice)
  - Services (ClusterIP for internal, LoadBalancer for API Gateway)
  - ConfigMaps (environment-specific config)
  - Secrets (sensitive data from AWS Secrets Manager)
  - HorizontalPodAutoscalers (auto-scale based on CPU/memory)
  - Ingress (Kong/Traefik)
```

### 4.3 Infrastructure as Code

**Selected: Terraform 1.6+**

```hcl
# infrastructure/terraform/main.tf

terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket = "tavx-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
module "vpc" {
  source = "./modules/vpc"

  cidr_block = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  cluster_name = "tavx-prod"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
}

# RDS PostgreSQL
module "rds" {
  source = "./modules/rds"

  instance_class    = "db.t3.medium"
  allocated_storage = 100
  engine_version    = "16.1"
  multi_az          = true
}

# ElastiCache Redis
module "redis" {
  source = "./modules/elasticache"

  node_type    = "cache.t3.micro"
  num_nodes    = 2
  engine_version = "7.0"
}

# S3 Buckets
module "s3" {
  source = "./modules/s3"

  buckets = [
    "tavx-vehicle-photos",
    "tavx-tour-audio",
    "tavx-profile-images",
    "tavx-backups"
  ]
}
```

### 4.4 CI/CD Pipeline

**Selected: GitHub Actions**

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run unit tests
        run: npm test

      - name: Run integration tests
        run: npm run test:integration

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push Docker images
        run: |
          docker build -t tavx/booking-service:${{ github.sha }} ./services/booking
          docker push tavx/booking-service:${{ github.sha }}
          # Repeat for other services...

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to EKS
        run: |
          aws eks update-kubeconfig --name tavx-prod
          kubectl set image deployment/booking-service \
            booking-service=tavx/booking-service:${{ github.sha }}
          kubectl rollout status deployment/booking-service
```

### 4.5 Monitoring & Observability

**Metrics: Prometheus + Grafana**
```yaml
Prometheus:
  - Scrapes metrics from all services
  - Retention: 15 days
  - Alertmanager for critical alerts

Grafana:
  - Pre-built dashboards for each service
  - Fleet status dashboard
  - Business metrics dashboard
  - Alert visualization

Key Metrics:
  - Request latency (p50, p95, p99)
  - Error rate
  - Request throughput
  - Database query time
  - Vehicle API response time
  - Tour session completion rate
```

**Logging: ELK Stack (Elasticsearch, Logstash, Kibana)**
```yaml
Alternative: AWS CloudWatch Logs (simpler, managed)

Log Aggregation:
  - All service logs centralized
  - Structured JSON logging
  - Correlation IDs for request tracing
  - Log retention: 30 days (searchable)

Log Levels:
  - ERROR: System failures, exceptions
  - WARN: Degraded performance, recoverable issues
  - INFO: Business events (booking created, tour started)
  - DEBUG: Detailed execution flow (dev only)
```

**Error Tracking: Sentry**
```yaml
Plan: Team ($26/month)
Features:
  - Real-time error notifications
  - Stack trace analysis
  - Release tracking
  - Performance monitoring
  - User feedback integration
```

**Application Performance Monitoring (APM): New Relic or DataDog**
```yaml
Recommendation: New Relic (better free tier)
Features:
  - Distributed tracing
  - Database query analysis
  - External service monitoring (Tesla API, Stripe)
  - Custom business metrics
```

---

## 5. Third-Party Services

### 5.1 Tesla API Integration

```yaml
API Version: Tesla Fleet API (OAuth 2.0)
Authentication: OAuth 2.0 with refresh tokens
Rate Limits:
  - 200 requests per 15 minutes per vehicle
  - Respect 429 responses
Key Endpoints:
  - Vehicle list
  - Vehicle state
  - Vehicle data
  - Vehicle commands (lock, unlock, flash lights)
  - Charge state
  - Climate state
Library: tesla-api-client (npm package) or custom wrapper
```

**Implementation:**
```typescript
// services/vehicle/src/clients/TeslaAPIClient.ts

import axios from 'axios';

export class TeslaAPIClient {
  private baseURL = 'https://fleet-api.prd.na.vn.cloud.tesla.com';
  private accessToken: string;

  async unlockVehicle(vehicleId: string): Promise<void> {
    await this.sendCommand(vehicleId, 'door_unlock');
  }

  async lockVehicle(vehicleId: string): Promise<void> {
    await this.sendCommand(vehicleId, 'door_lock');
  }

  async getVehicleData(vehicleId: string) {
    const response = await axios.get(
      `${this.baseURL}/api/1/vehicles/${vehicleId}/vehicle_data`,
      {
        headers: { Authorization: `Bearer ${this.accessToken}` }
      }
    );
    return response.data;
  }

  private async sendCommand(vehicleId: string, command: string) {
    // Implement with retry logic and rate limiting
  }
}
```

### 5.2 Vapi (Voice AI)

```yaml
Plan: Startup ($499/month, 15 hours included)
Features:
  - Custom voice agents
  - Webhook integrations
  - Call analytics
  - Conversation logging
Phone Number: Purchase through Vapi or bring Twilio number
```

**Agent Configuration:**
```json
{
  "assistantId": "check-in-agent",
  "name": "Check-In Assistant",
  "model": {
    "provider": "openai",
    "model": "gpt-4",
    "systemPrompt": "You are a friendly check-in assistant for Tesla EV Rentals..."
  },
  "voice": {
    "provider": "11labs",
    "voiceId": "professional_female"
  },
  "webhooks": {
    "onCallStart": "https://api.tavx.com/webhooks/vapi/call-start",
    "onCallEnd": "https://api.tavx.com/webhooks/vapi/call-end",
    "onMessageReceived": "https://api.tavx.com/webhooks/vapi/message"
  }
}
```

### 5.3 VoiceMap (GPS Tours)

```yaml
Plan: Publisher ($99/month)
Features:
  - Unlimited tours
  - GPS-triggered audio
  - Offline mode
  - Analytics
Integration: REST API + Mobile SDK
```

**Alternative:** Build custom tour engine using:
- react-native-maps
- Geofencing (expo-location)
- Audio playback (expo-av)
- Custom CMS for content

### 5.4 Twilio (SMS/MMS)

```yaml
Services Used:
  - Programmable SMS
  - Programmable Voice (backup for Vapi)
  - Phone number(s): +1 510 area code

Pricing:
  - SMS: $0.0079 per message (US)
  - MMS: $0.02 per message
  - Phone number: $1/month

Estimated Cost: ~$200/month (1000 bookings)
```

### 5.5 Stripe (Payments)

```yaml
Products:
  - Stripe Payments (standard processing)
  - Stripe Connect (for partner payouts)

Pricing:
  - 2.9% + $0.30 per transaction
  - No monthly fees
  - Connect: +0.5% for platform fee

Features Needed:
  - Payment intents
  - Webhooks for payment events
  - Refunds and disputes
  - Connected accounts for partners
  - Automatic payouts
```

### 5.6 SendGrid (Email)

```yaml
Plan: Essentials ($19.95/month, 50K emails)
Features:
  - Transactional emails
  - Email templates
  - Delivery analytics
  - Webhook events

Email Types:
  - Booking confirmation
  - Reminder (24 hours before)
  - Check-in instructions
  - Tour completion thank you
  - Review request
  - Monthly partner statements
```

### 5.7 Google Maps Platform

```yaml
APIs Used:
  - Maps JavaScript API (web)
  - Maps SDK for Android/iOS (mobile)
  - Geocoding API
  - Directions API
  - Distance Matrix API

Pricing: $200/month free credit
After credits:
  - $7 per 1000 map loads
  - $5 per 1000 geocoding requests
```

**Alternative:** Mapbox (similar pricing, better customization)

### 5.8 AWS Rekognition (Damage Detection)

```yaml
Service: Image Analysis
Features Used:
  - Object and scene detection
  - Text in image detection
  - Image comparison (checkin vs checkout)

Pricing:
  - $1 per 1000 images analyzed
  - First 5000 images/month free

Estimated: ~$50/month (10,000 photos)
```

### 5.9 Slack (Internal Notifications)

```yaml
Workspace: TAV-X Operations
Channels:
  - #alerts (system errors, high priority)
  - #operations (bookings, check-ins)
  - #fleet-status (vehicle issues)
  - #revenue (daily summaries)

Integration: Incoming Webhooks (free)
```

### 5.10 Mixpanel (Product Analytics)

```yaml
Plan: Free tier (100K tracked users)
Events Tracked:
  - Booking flow steps
  - Tour start/completion
  - Waypoint visits
  - App feature usage
  - Conversion funnels

Alternative: PostHog (open-source, self-hosted)
```

---

## 6. Development Tools

### 6.1 Version Control

**Git + GitHub**
```yaml
Repository: github.com/tavx/tavx-platform
Branch Strategy:
  - main (production)
  - staging (pre-production)
  - develop (active development)
  - feature/* (new features)
  - bugfix/* (bug fixes)

Protected Branches: main, staging
Required Reviews: 1 approval
CI Checks: Must pass before merge
```

### 6.2 Code Quality

**Linting & Formatting:**
```json
{
  "devDependencies": {
    "eslint": "^8.55.0",
    "@typescript-eslint/eslint-plugin": "^6.15.0",
    "@typescript-eslint/parser": "^6.15.0",
    "prettier": "^3.1.1",
    "husky": "^8.0.3",
    "lint-staged": "^15.2.0"
  }
}
```

**Pre-commit Hooks:**
```json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

### 6.3 Testing

**Unit Tests: Jest + Supertest**
```json
{
  "devDependencies": {
    "jest": "^29.7.0",
    "@types/jest": "^29.5.11",
    "ts-jest": "^29.1.1",
    "supertest": "^6.3.3",
    "@types/supertest": "^6.0.2"
  }
}
```

**Integration Tests: Jest + Testcontainers**
```typescript
// Spin up real PostgreSQL, Redis for integration tests
import { PostgreSqlContainer } from '@testcontainers/postgresql';
import { RedisContainer } from '@testcontainers/redis';
```

**E2E Tests: Playwright**
```yaml
Browser Testing: Chromium, Firefox, WebKit
Test Coverage:
  - Complete booking flow
  - Dashboard interactions
  - Mobile app core features
```

**Load Testing: k6**
```javascript
// scripts/load-tests/booking-flow.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],   // Error rate under 1%
  },
};

export default function () {
  const res = http.get('https://api.tavx.com/v1/vehicles/availability');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

### 6.4 API Documentation

**OpenAPI (Swagger)**
```typescript
// Automatically generate from code
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'TAV-X API',
      version: '1.0.0',
    },
    servers: [
      { url: 'https://api.tavx.com/v1' }
    ]
  },
  apis: ['./src/routes/*.ts'],
};

const specs = swaggerJsdoc(options);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
```

### 6.5 Local Development

**Development Environment:**
```yaml
Prerequisites:
  - Node.js 20 LTS
  - Docker Desktop
  - Git
  - VS Code (recommended)

VS Code Extensions:
  - ESLint
  - Prettier
  - Docker
  - Prisma
  - REST Client
  - GitLens

Quick Start:
  1. git clone repo
  2. npm install (in each service directory)
  3. docker-compose up -d
  4. npm run db:migrate
  5. npm run dev
```

---

## 7. Cost Analysis

### 7.1 MVP Phase (Months 1-3) - 10 Vehicles

| Category | Service | Monthly Cost |
|----------|---------|--------------|
| **Infrastructure** |  |  |
| | AWS (EC2, RDS, S3, misc) | $300 |
| | Domain + SSL | $15 |
| **Databases** |  |  |
| | Airtable (Team) | $60 |
| | Redis (ElastiCache) | $15 |
| | Qdrant (Free tier) | $0 |
| **Backend Services** |  |  |
| | API hosting (EC2) | Included above |
| **Third-Party APIs** |  |  |
| | Tesla API | $0 |
| | Vapi (Voice AI) | $499 |
| | VoiceMap | $99 |
| | Twilio (SMS) | $100 |
| | Stripe | Per-transaction |
| | SendGrid | $20 |
| | Google Maps API | $50 |
| | AWS Rekognition | $30 |
| | Mixpanel | $0 |
| **Frontend** |  |  |
| | WordPress Hosting | $30 |
| | Retool | $150 |
| **Monitoring** |  |  |
| | Sentry | $26 |
| | Prometheus + Grafana (self-hosted) | $0 |
| **CI/CD** |  |  |
| | GitHub Actions | $0 (free tier) |
| **Total** |  | **~$1,394/month** |
| **Annual** |  | **~$16,728** |

### 7.2 Production Phase (Months 7-12) - 100 Vehicles

| Category | Service | Monthly Cost |
|----------|---------|--------------|
| **Infrastructure** |  |  |
| | AWS EKS + RDS + S3 | $800 |
| | CloudFront CDN | $50 |
| **Databases** |  |  |
| | PostgreSQL RDS | Included above |
| | Redis ElastiCache | $60 |
| | Qdrant (1GB plan) | $25 |
| **Third-Party APIs** |  |  |
| | Vapi (Scale plan) | $999 |
| | VoiceMap | $99 |
| | Twilio | $500 |
| | SendGrid | $90 |
| | Google Maps | $200 |
| | AWS Rekognition | $200 |
| **Frontend** |  |  |
| | WordPress Hosting | $50 |
| | Custom Dashboard (hosting) | Included in EKS |
| **Monitoring** |  |  |
| | Sentry | $89 |
| | New Relic | $99 |
| **CI/CD** |  |  |
| | GitHub Actions | $50 |
| **Total** |  | **~$3,311/month** |
| **Annual** |  | **~$39,732** |

### 7.3 Cost Optimization Strategies

1. **Use AWS Reserved Instances** (save 30-40%)
2. **Implement aggressive caching** (reduce API calls)
3. **Optimize image storage** (compress, use S3 lifecycle policies)
4. **Negotiate volume discounts** with Vapi, Twilio at scale
5. **Self-host what makes sense** (Grafana, RabbitMQ vs managed)

---

## 8. Implementation Phases

### Phase 1: MVP Foundation (Weeks 1-4)

**Goal:** Local development environment + core architecture

```yaml
Week 1: Project Setup
  - Initialize monorepo structure
  - Set up Docker Compose for local services
  - Configure TypeScript + ESLint + Prettier
  - Create base microservice templates
  - Set up GitHub repo and CI/CD skeleton

Week 2: Database & Auth
  - Set up Airtable base with initial schema
  - Build Prisma schema for future PostgreSQL migration
  - Implement auth-service (JWT authentication)
  - Create user registration and login
  - Set up Redis for session management

Week 3: Core Services
  - Build booking-service (CRUD operations)
  - Build vehicle-service (Tesla API integration)
  - Implement RabbitMQ event bus
  - Create shared TypeScript types package
  - Set up API Gateway (Kong) locally

Week 4: Testing & Documentation
  - Write unit tests for critical paths
  - Set up integration test framework
  - Generate OpenAPI documentation
  - Create developer README
  - Conduct internal code review
```

### Phase 2: MVP Features (Weeks 5-8)

**Goal:** Functional booking + voice check-in + basic tour

```yaml
Week 5: Booking System
  - WordPress + WooCommerce setup
  - Custom booking plugin development
  - Integration with booking-service API
  - Stripe payment integration
  - Automated confirmation emails

Week 6: Voice Check-In
  - Vapi account setup and configuration
  - Build voice-service with webhook handlers
  - Implement check-in conversation flow
  - Twilio MMS photo upload integration
  - AWS S3 photo storage

Week 7: Tour Engine
  - Build tour-service
  - VoiceMap integration
  - Create Oakland Heritage Tour content
  - Record narration audio
  - Build basic React Native tablet app

Week 8: Operations Dashboard
  - Set up Retool workspace
  - Build fleet status dashboard
  - Create active rentals view
  - Build maintenance queue
  - Implement basic analytics
```

### Phase 3: MVP Launch (Weeks 9-12)

**Goal:** Deploy to production, pilot with 10 vehicles

```yaml
Week 9: AWS Deployment
  - Set up AWS account and VPC
  - Deploy PostgreSQL RDS
  - Deploy ElastiCache Redis
  - Configure S3 buckets
  - Set up CloudWatch logging

Week 10: Production Services
  - Deploy all microservices to EC2
  - Configure Kong API Gateway
  - Set up domain and SSL certificates
  - Configure production environment variables
  - Implement backup and disaster recovery

Week 11: Testing & Refinement
  - End-to-end testing with real Tesla
  - Load testing with k6
  - Security audit
  - Performance optimization
  - Bug fixes

Week 12: Soft Launch
  - Onboard 5 vehicles
  - Train operations team
  - Launch to friends & family
  - Monitor logs and metrics
  - Iterate based on feedback
```

### Phase 4: Scale to Production (Months 4-6)

**Goal:** 30 vehicles, full feature set

```yaml
Month 4:
  - Add Black Panther Party Historical Tour
  - Add Bay Area Scenic Tour
  - Build partner portal
  - Implement automated partner statements
  - Hire 2 Philippines VAs

Month 5:
  - Migrate from Airtable to PostgreSQL
  - Deploy Kubernetes (EKS)
  - Implement auto-scaling
  - Build advanced analytics dashboards
  - Launch referral program

Month 6:
  - Scale to 30 vehicles
  - Onboard 5 fleet partners
  - Launch public marketing campaign
  - Implement customer mobile app (Phase 1)
  - Optimize costs and performance
```

### Phase 5: Enterprise (Months 7-12)

**Goal:** 100 vehicles, partnerships, expansion prep

```yaml
Q3 (Months 7-9):
  - Scale to 60 vehicles
  - Partner with 5 hotels
  - Integrate with Expedia, Viator
  - Build full custom React dashboard
  - Implement advanced AI features

Q4 (Months 10-12):
  - Scale to 100 vehicles
  - 10+ fleet partners
  - Full customer mobile app
  - Expand to San Francisco
  - Create franchise playbook
```

---

## 9. Alternative Considerations

### 9.1 Backend Alternatives

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **Node.js + Express** (Selected) | Fast, async I/O, huge ecosystem | Callback hell if not careful | ✅ Best choice |
| **Python + FastAPI** | Great for ML, clean async syntax | Slower than Node, less real-time | ❌ Not ideal for real-time |
| **Go + Gin** | Blazing fast, great concurrency | Smaller ecosystem, steeper learning | ⚠️ Consider for high-traffic services |
| **Ruby on Rails** | Rapid development, mature | Slower runtime, less async | ❌ Too slow for real-time needs |

### 9.2 Database Alternatives

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **PostgreSQL** (Selected) | ACID, relational, PostGIS for geo | Setup complexity | ✅ Best choice |
| **MongoDB** | Flexible schema, fast writes | No ACID, poor for relational data | ❌ Bad fit for bookings |
| **MySQL** | Popular, good performance | Less features than Postgres | ⚠️ Acceptable alternative |
| **Airtable → PostgreSQL** (Selected) | Fast MVP → Scalable production | Migration effort | ✅ Best of both worlds |

### 9.3 Frontend Alternatives

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **WordPress** (Selected for booking) | Fast setup, familiar, SEO | Less flexible | ✅ Perfect for public site |
| **Next.js + React** | Modern, fast, flexible | Longer dev time | ⚠️ Consider for v2 |
| **Vue + Nuxt** | Easy to learn, good DX | Smaller ecosystem | ❌ Team not familiar |

### 9.4 Mobile Alternatives

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **React Native** (Selected) | Code sharing, fast dev | Performance issues (rare) | ✅ Best choice |
| **Flutter** | Great performance, beautiful UI | Dart language, larger app size | ⚠️ If team knows Dart |
| **Native (Swift/Kotlin)** | Best performance | 2x dev effort | ❌ Too expensive |

### 9.5 Cloud Provider Alternatives

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **AWS** (Selected) | Most comprehensive, mature | Complex, can be expensive | ✅ Best choice |
| **Google Cloud** | Good Kubernetes, ML tools | Less mature than AWS | ⚠️ Acceptable |
| **Azure** | Good for Microsoft shops | Less popular for startups | ❌ Not ideal |
| **DigitalOcean** | Simple, cheap | Limited services | ❌ Not scalable enough |

---

## 10. Security Best Practices

### 10.1 API Security

```yaml
Authentication:
  - JWT tokens with 15-minute expiry
  - Refresh tokens with 7-day expiry
  - HTTP-only cookies for web clients

Authorization:
  - Role-based access control (RBAC)
  - Principle of least privilege
  - Resource-level permissions

Input Validation:
  - Validate all user input
  - Sanitize data before database queries
  - Use Joi or Zod for schema validation

Rate Limiting:
  - 100 requests per 15 minutes (general API)
  - 5 requests per 15 minutes (auth endpoints)
  - IP-based + user-based limiting

HTTPS:
  - TLS 1.3 only
  - HSTS enabled
  - Secure cipher suites
```

### 10.2 Data Protection

```yaml
Encryption at Rest:
  - Database: AWS RDS encryption enabled
  - Files: S3 server-side encryption (SSE-S3)
  - Sensitive fields: Application-level AES-256

Encryption in Transit:
  - HTTPS for all external communication
  - TLS for internal service communication
  - VPN for admin access

PII Handling:
  - Encrypt driver's license numbers
  - Mask credit card numbers (via Stripe tokens)
  - GDPR compliance (right to erasure)
  - CCPA compliance (data access requests)
```

### 10.3 Secret Management

```yaml
Development:
  - .env files (gitignored)
  - Never commit secrets to Git

Production:
  - AWS Secrets Manager
  - Automatic secret rotation (90 days)
  - IAM roles for service access
  - No hardcoded credentials
```

---

## 11. Final Recommendations

### 11.1 Must-Have for MVP
1. ✅ **Airtable → PostgreSQL migration path defined from Day 1**
2. ✅ **Comprehensive error handling and logging**
3. ✅ **Automated database backups**
4. ✅ **Monitoring and alerting (Sentry + CloudWatch)**
5. ✅ **Load testing before public launch**

### 11.2 Nice-to-Have (Defer to Phase 2)
1. ⚠️ Advanced AI damage detection (start with manual review)
2. ⚠️ Custom mobile app for customers (web-first is fine)
3. ⚠️ Multi-language tours (English-only MVP)
4. ⚠️ Complex pricing rules (flat rates first)
5. ⚠️ Native integrations with OTAs (manual entry MVP)

### 11.3 Technical Debt to Avoid
1. ❌ **Don't skip database indexes** (kills performance)
2. ❌ **Don't ignore rate limiting** (exposes to attacks)
3. ❌ **Don't skip tests** (you'll regret it)
4. ❌ **Don't hardcode configuration** (use env vars)
5. ❌ **Don't ignore security** (encryptions, HTTPS, validation)

---

## 12. Next Steps

### Week 1 Action Items

**Infrastructure Setup:**
- [ ] Create AWS account
- [ ] Set up GitHub repository
- [ ] Configure domain DNS
- [ ] Initialize Terraform project
- [ ] Set up development Docker Compose

**Service Accounts:**
- [ ] Register for Tesla API access
- [ ] Create Vapi account
- [ ] Set up Twilio account
- [ ] Create Stripe account
- [ ] Set up VoiceMap publisher account
- [ ] Create SendGrid account
- [ ] Set up Google Cloud account (for Maps API)

**Development Environment:**
- [ ] Install Node.js 20 LTS
- [ ] Install Docker Desktop
- [ ] Install VS Code + extensions
- [ ] Clone repository and install dependencies
- [ ] Create .env files for each service

**Documentation:**
- [ ] Review complete PRD
- [ ] Study all 3 architecture specification documents
- [ ] Review this tech stack document
- [ ] Create team onboarding guide

---

## Appendix A: Complete Dependency List

### Shared Dependencies (all services)
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "typescript": "^5.3.0",
    "dotenv": "^16.3.1",
    "helmet": "^7.1.0",
    "cors": "^2.8.5",
    "compression": "^1.7.4",
    "morgan": "^1.10.0",
    "winston": "^3.11.0",
    "joi": "^17.11.0",
    "axios": "^1.6.2",
    "jsonwebtoken": "^9.0.2",
    "bcrypt": "^5.1.1",
    "@prisma/client": "^5.7.0",
    "ioredis": "^5.3.2",
    "amqplib": "^0.10.3",
    "@sentry/node": "^7.86.0",
    "uuid": "^9.0.1"
  },
  "devDependencies": {
    "@types/node": "^20.10.0",
    "@types/express": "^4.17.21",
    "ts-node": "^10.9.2",
    "nodemon": "^3.0.2",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.11",
    "ts-jest": "^29.1.1",
    "supertest": "^6.3.3",
    "@types/supertest": "^6.0.2",
    "eslint": "^8.55.0",
    "@typescript-eslint/eslint-plugin": "^6.15.0",
    "prettier": "^3.1.1"
  }
}
```

---

**Document Status:** ✅ Ready for Implementation
**Last Updated:** November 19, 2025
**Next Review:** After MVP Launch (Month 3)
