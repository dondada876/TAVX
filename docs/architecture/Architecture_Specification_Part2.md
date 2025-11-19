# TAV-X Architecture Specification - Part 2
## Advanced Systems & Implementation Guide

---

## 6. DEPLOYMENT & INFRASTRUCTURE

### 6.1 Docker Configuration

**docker-compose.yml (Development)**

```yaml
version: '3.8'

services:
  # API Gateway
  kong:
    image: kong:latest
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: postgres
      KONG_PG_DATABASE: kong
      KONG_PG_USER: kong
      KONG_PG_PASSWORD: ${KONG_DB_PASSWORD}
    ports:
      - "8000:8000"
      - "8001:8001"
    depends_on:
      - postgres

  # Backend Services
  booking-service:
    build: ./services/booking-service
    environment:
      NODE_ENV: development
      DATABASE_URL: ${DATABASE_URL}
      REDIS_URL: ${REDIS_URL}
      JWT_SECRET: ${JWT_SECRET}
    ports:
      - "3001:3001"
    depends_on:
      - postgres
      - redis
      - rabbitmq

  vehicle-service:
    build: ./services/vehicle-service
    environment:
      NODE_ENV: development
      DATABASE_URL: ${DATABASE_URL}
      REDIS_URL: ${REDIS_URL}
      TESLA_API_KEY: ${TESLA_API_KEY}
    ports:
      - "3002:3002"
      - "3003:3003"
    depends_on:
      - postgres
      - redis

  tour-service:
    build: ./services/tour-service
    environment:
      NODE_ENV: development
      DATABASE_URL: ${DATABASE_URL}
      REDIS_URL: ${REDIS_URL}
      VOICEMAP_API_KEY: ${VOICEMAP_API_KEY}
    ports:
      - "3004:3004"
    depends_on:
      - postgres
      - redis

  payment-service:
    build: ./services/payment-service
    environment:
      NODE_ENV: development
      DATABASE_URL: ${DATABASE_URL}
      STRIPE_SECRET_KEY: ${STRIPE_SECRET_KEY}
    ports:
      - "3005:3005"
    depends_on:
      - postgres

  # Databases
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: tavx
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: tavx
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init.sql

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_data:/qdrant/storage

  # Message Queue
  rabbitmq:
    image: rabbitmq:3-management-alpine
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: tavx
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq

  # Automation
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      N8N_BASIC_AUTH_ACTIVE: true
      N8N_BASIC_AUTH_USER: ${N8N_USER}
      N8N_BASIC_AUTH_PASSWORD: ${N8N_PASSWORD}
      GENERIC_TIMEZONE: America/Los_Angeles
    volumes:
      - n8n_data:/home/node/.n8n

  # Monitoring
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  postgres_data:
  redis_data:
  qdrant_data:
  rabbitmq_data:
  n8n_data:
  prometheus_data:
  grafana_data:
```

### 6.2 Kubernetes Deployment (Production)

**k8s/booking-service-deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: booking-service
  namespace: tavx-production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: booking-service
  template:
    metadata:
      labels:
        app: booking-service
    spec:
      containers:
      - name: booking-service
        image: tavx/booking-service:latest
        ports:
        - containerPort: 3001
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secrets
              key: url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-secrets
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: booking-service
  namespace: tavx-production
spec:
  selector:
    app: booking-service
  ports:
  - port: 80
    targetPort: 3001
  type: ClusterIP
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: booking-service-hpa
  namespace: tavx-production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: booking-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### 6.3 Infrastructure as Code (Terraform)

**terraform/main.tf**

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "tavx-terraform-state"
    key    = "production/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "tavx-production-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  tags = {
    Environment = "production"
    Project     = "TAV-X"
  }
}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = "tavx-production"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  eks_managed_node_groups = {
    general = {
      desired_size = 3
      min_size     = 2
      max_size     = 10
      
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "TAV-X"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "main" {
  identifier     = "tavx-production-db"
  engine         = "postgres"
  engine_version = "16.1"
  instance_class = "db.t3.large"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_encrypted     = true
  
  db_name  = "tavx"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  multi_az = true
  
  tags = {
    Environment = "production"
    Project     = "TAV-X"
  }
}

# ElastiCache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "tavx-production-redis"
  engine               = "redis"
  node_type            = "cache.t3.medium"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  
  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]
  
  tags = {
    Environment = "production"
    Project     = "TAV-X"
  }
}

# S3 Buckets
resource "aws_s3_bucket" "uploads" {
  bucket = "tavx-production-uploads"
  
  tags = {
    Environment = "production"
    Project     = "TAV-X"
  }
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "archive-old-photos"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# CloudFront CDN
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.uploads.bucket_regional_domain_name
    origin_id   = "S3-uploads"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.uploads.cloudfront_access_identity_path
    }
  }
  
  enabled = true
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-uploads"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Load Balancer
resource "aws_lb" "main" {
  name               = "tavx-production-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
  
  tags = {
    Environment = "production"
    Project     = "TAV-X"
  }
}

# Output values
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "cdn_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
```

---

## 7. TESTING STRATEGY

### 7.1 Unit Tests

```typescript
// services/booking-service/tests/BookingService.test.ts

import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { BookingService } from '../src/services/BookingService';
import { AirtableClient } from '../src/clients/AirtableClient';
import { StripeClient } from '../src/clients/StripeClient';

jest.mock('../src/clients/AirtableClient');
jest.mock('../src/clients/StripeClient');

describe('BookingService', () => {
  let bookingService: BookingService;
  let mockAirtable: jest.Mocked<AirtableClient>;
  let mockStripe: jest.Mocked<StripeClient>;

  beforeEach(() => {
    mockAirtable = new AirtableClient() as jest.Mocked<AirtableClient>;
    mockStripe = new StripeClient('test_key') as jest.Mocked<StripeClient>;
    bookingService = new BookingService(mockAirtable, mockStripe);
  });

  describe('createBooking', () => {
    it('should create a booking successfully', async () => {
      // Arrange
      const bookingData = {
        vehicleId: 'vehicle-123',
        customerId: 'customer-123',
        startDate: new Date('2025-12-01'),
        endDate: new Date('2025-12-07'),
        totalPrice: 2800
      };

      mockAirtable.checkAvailability.mockResolvedValue(true);
      mockStripe.createPaymentIntent.mockResolvedValue({
        id: 'pi_123',
        status: 'succeeded'
      } as any);
      mockAirtable.createBooking.mockResolvedValue({
        id: 'booking-123',
        confirmationCode: 'ABC123',
        ...bookingData
      });

      // Act
      const result = await bookingService.createBooking(bookingData);

      // Assert
      expect(result.confirmationCode).toBe('ABC123');
      expect(mockAirtable.checkAvailability).toHaveBeenCalledWith(
        'vehicle-123',
        bookingData.startDate,
        bookingData.endDate
      );
      expect(mockStripe.createPaymentIntent).toHaveBeenCalledWith({
        amount: 2800,
        metadata: expect.any(Object)
      });
    });

    it('should throw error if vehicle not available', async () => {
      // Arrange
      mockAirtable.checkAvailability.mockResolvedValue(false);

      // Act & Assert
      await expect(bookingService.createBooking({} as any)).rejects.toThrow(
        'Vehicle not available'
      );
    });
  });

  describe('calculatePrice', () => {
    it('should calculate correct price for 7-day rental', () => {
      const days = 7;
      const dailyRate = 400;
      
      const price = bookingService.calculatePrice(days, dailyRate);
      
      expect(price).toBe(2800);
    });

    it('should apply weekly discount', () => {
      const days = 7;
      const dailyRate = 400;
      
      const price = bookingService.calculatePrice(days, dailyRate, 'WEEK10');
      
      expect(price).toBe(2520); // 10% discount
    });
  });
});
```

### 7.2 Integration Tests

```typescript
// tests/integration/booking-flow.test.ts

import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import request from 'supertest';
import { app } from '../src/app';
import { setupTestDatabase, teardownTestDatabase } from './helpers/database';

describe('Booking Flow Integration', () => {
  let authToken: string;
  let vehicleId: string;

  beforeAll(async () => {
    await setupTestDatabase();
    
    // Create test user and get auth token
    const authResponse = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'Test123!',
        firstName: 'Test',
        lastName: 'User',
        phone: '+15555551234'
      });
    
    authToken = authResponse.body.data.token;
    
    // Create test vehicle
    vehicleId = 'test-vehicle-123';
  });

  afterAll(async () => {
    await teardownTestDatabase();
  });

  it('should complete full booking flow', async () => {
    // 1. Check availability
    const availabilityResponse = await request(app)
      .get('/api/vehicles/availability')
      .query({
        startDate: '2025-12-01T10:00:00Z',
        endDate: '2025-12-07T10:00:00Z'
      });
    
    expect(availabilityResponse.status).toBe(200);
    expect(availabilityResponse.body.data.length).toBeGreaterThan(0);

    // 2. Create booking
    const bookingResponse = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        vehicleId,
        pickupDatetime: '2025-12-01T10:00:00Z',
        returnDatetime: '2025-12-07T10:00:00Z',
        tourPackageId: 'tour-heritage',
        promoCode: 'TEST10'
      });
    
    expect(bookingResponse.status).toBe(201);
    expect(bookingResponse.body.data.confirmationCode).toBeDefined();
    
    const confirmationCode = bookingResponse.body.data.confirmationCode;

    // 3. Retrieve booking
    const getBookingResponse = await request(app)
      .get(`/api/bookings/${confirmationCode}`)
      .set('Authorization', `Bearer ${authToken}`);
    
    expect(getBookingResponse.status).toBe(200);
    expect(getBookingResponse.body.data.status).toBe('confirmed');

    // 4. Start check-in
    const checkinResponse = await request(app)
      .post(`/api/bookings/${getBookingResponse.body.data.id}/checkin`)
      .set('Authorization', `Bearer ${authToken}`);
    
    expect(checkinResponse.status).toBe(200);
    expect(checkinResponse.body.data.callId).toBeDefined();
  });
});
```

### 7.3 End-to-End Tests (Cypress)

```typescript
// cypress/e2e/booking-flow.cy.ts

describe('Customer Booking Flow', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('should complete a booking from start to finish', () => {
    // 1. Homepage
    cy.contains('Book Your Tesla Experience').should('be.visible');
    cy.get('[data-testid="book-now-button"]').click();

    // 2. Select dates
    cy.get('[data-testid="start-date"]').type('2025-12-01');
    cy.get('[data-testid="end-date"]').type('2025-12-07');
    cy.get('[data-testid="search-button"]').click();

    // 3. Choose vehicle
    cy.get('[data-testid="vehicle-card"]').first().click();
    cy.contains('Model Y').should('be.visible');
    cy.get('[data-testid="select-vehicle-button"]').click();

    // 4. Choose tour
    cy.contains('Oakland Heritage Tour').click();
    cy.get('[data-testid="continue-button"]').click();

    // 5. Driver information
    cy.get('[data-testid="first-name"]').type('John');
    cy.get('[data-testid="last-name"]').type('Doe');
    cy.get('[data-testid="email"]').type('john@example.com');
    cy.get('[data-testid="phone"]').type('5555551234');
    cy.get('[data-testid="drivers-license"]').type('D1234567');
    cy.get('[data-testid="continue-button"]').click();

    // 6. Payment
    cy.get('[data-testid="card-number"]').type('4242424242424242');
    cy.get('[data-testid="expiry"]').type('1225');
    cy.get('[data-testid="cvc"]').type('123');
    cy.get('[data-testid="submit-payment"]').click();

    // 7. Confirmation
    cy.contains('Booking Confirmed!').should('be.visible');
    cy.get('[data-testid="confirmation-code"]').should('exist');
    
    // Save confirmation code
    cy.get('[data-testid="confirmation-code"]').invoke('text').as('confirmationCode');
  });
});
```

---

## 8. MONITORING & OBSERVABILITY

### 8.1 Prometheus Metrics

```typescript
// middleware/metrics.ts

import client from 'prom-client';

// Create a Registry
export const register = new client.Registry();

// Default metrics
client.collectDefaultMetrics({ register });

// Custom metrics
export const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

export const bookingCounter = new client.Counter({
  name: 'bookings_total',
  help: 'Total number of bookings',
  labelNames: ['status', 'source']
});

export const activeRentalsGauge = new client.Gauge({
  name: 'active_rentals',
  help: 'Number of currently active rentals'
});

export const vehicleUtilizationGauge = new client.Gauge({
  name: 'vehicle_utilization_percent',
  help: 'Vehicle fleet utilization percentage',
  labelNames: ['vehicle_id']
});

register.registerMetric(httpRequestDuration);
register.registerMetric(bookingCounter);
register.registerMetric(activeRentalsGauge);
register.registerMetric(vehicleUtilizationGauge);

// Middleware to track request duration
export const metricsMiddleware = (req: any, res: any, next: any) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.labels(req.method, req.route?.path || req.path, res.statusCode).observe(duration);
  });
  
  next();
};

// Metrics endpoint
import express from 'express';
const router = express.Router();

router.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

export { router as metricsRouter };
```

### 8.2 Structured Logging

```typescript
// utils/logger.ts

import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: process.env.SERVICE_NAME || 'tavx-api',
    environment: process.env.NODE_ENV
  },
  transports: [
    // Write to console
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    // Write to file
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error'
    }),
    new winston.transports.File({
      filename: 'logs/combined.log'
    })
  ]
});

// Add request ID to all logs
export const requestLogger = (req: any, res: any, next: any) => {
  req.id = crypto.randomUUID();
  req.logger = logger.child({ requestId: req.id });
  
  req.logger.info('Incoming request', {
    method: req.method,
    path: req.path,
    query: req.query,
    ip: req.ip
  });
  
  next();
};

export default logger;

// Usage
import logger from './utils/logger';

logger.info('Booking created', {
  bookingId: 'booking-123',
  customerId: 'customer-456',
  amount: 2800
});

logger.error('Payment failed', {
  bookingId: 'booking-123',
  error: error.message,
  stack: error.stack
});
```

### 8.3 Grafana Dashboards

```json
// grafana/dashboards/tavx-overview.json

{
  "dashboard": {
    "title": "TAV-X Operations Overview",
    "panels": [
      {
        "title": "Active Rentals",
        "type": "graph",
        "targets": [
          {
            "expr": "active_rentals",
            "legendFormat": "Active Rentals"
          }
        ]
      },
      {
        "title": "Bookings per Hour",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(bookings_total[1h])",
            "legendFormat": "Bookings"
          }
        ]
      },
      {
        "title": "API Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p95"
          },
          {
            "expr": "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p99"
          }
        ]
      },
      {
        "title": "Vehicle Utilization",
        "type": "gauge",
        "targets": [
          {
            "expr": "avg(vehicle_utilization_percent)",
            "legendFormat": "Utilization %"
          }
        ]
      },
      {
        "title": "Revenue Today",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(increase(booking_revenue_total[24h]))",
            "legendFormat": "Revenue"
          }
        ]
      }
    ]
  }
}
```

---

## 9. VOICE AI SYSTEM (VAPI) COMPLETE SETUP

### 9.1 Voice Agent Configuration

```typescript
// scripts/setup-vapi-assistants.ts

import { VapiClient } from '../src/clients/VapiClient';

const vapi = new VapiClient(process.env.VAPI_API_KEY!);

// Check-in Assistant
const checkinAssistant = {
  name: 'TAV-X Check-in Agent',
  model: {
    provider: 'openai',
    model: 'gpt-4',
    messages: [
      {
        role: 'system',
        content: `You are a friendly AI assistant for Tesla EV Rentals (TAV-X). Your job is to guide customers through the vehicle check-in process.

RESPONSIBILITIES:
1. Verify the customer's booking using their confirmation code
2. Guide them through a vehicle inspection
3. Request photos of the vehicle exterior (4 sides)
4. Provide safety instructions
5. Explain tour features and tablet usage
6. Unlock the vehicle once everything is confirmed

PERSONALITY:
- Friendly and professional
- Clear and concise
- Patient and helpful
- Safety-focused

CONVERSATION FLOW:
1. Greeting and confirmation code request
2. Verify booking details
3. Guide exterior inspection (request 4 photos via SMS)
4. Provide safety briefing
5. Explain tour tablet and features
6. Unlock vehicle
7. Wish them a great trip

You have access to these functions:
- verify_booking(confirmation_code)
- send_sms(phone_number, message)
- request_photos(booking_id, phone_number)
- unlock_vehicle(vehicle_id)
- log_inspection(booking_id, notes)

IMPORTANT: Always confirm the customer understands each step before moving forward. If you detect any concerns or damage, flag it immediately and notify operations.`
      }
    ]
  },
  voice: {
    provider: 'elevenlabs',
    voiceId: 'EXAVITQu4vr4xnSDxMaL' // Bella - Friendly female voice
  },
  functions: [
    {
      name: 'verify_booking',
      description: 'Verify customer booking using confirmation code',
      parameters: {
        type: 'object',
        properties: {
          confirmation_code: {
            type: 'string',
            description: 'The 6-character booking confirmation code'
          }
        },
        required: ['confirmation_code']
      }
    },
    {
      name: 'send_sms',
      description: 'Send SMS message to customer',
      parameters: {
        type: 'object',
        properties: {
          phone_number: {
            type: 'string',
            description: 'Customer phone number'
          },
          message: {
            type: 'string',
            description: 'Message content'
          }
        },
        required: ['phone_number', 'message']
      }
    },
    {
      name: 'unlock_vehicle',
      description: 'Unlock the Tesla vehicle',
      parameters: {
        type: 'object',
        properties: {
          vehicle_id: {
            type: 'string',
            description: 'Unique vehicle identifier'
          }
        },
        required: ['vehicle_id']
      }
    }
  ]
};

// Check-out Assistant
const checkoutAssistant = {
  name: 'TAV-X Check-out Agent',
  model: {
    provider: 'openai',
    model: 'gpt-4',
    messages: [
      {
        role: 'system',
        content: `You are the check-out assistant for Tesla EV Rentals (TAV-X). Your job is to guide customers through the vehicle return process.

RESPONSIBILITIES:
1. Verify the booking
2. Guide final vehicle inspection
3. Request photos of vehicle exterior and interior
4. Check for damage or cleanliness issues
5. Confirm mileage and battery level
6. Process final payment if needed
7. Lock the vehicle
8. Request customer feedback

PERSONALITY:
- Friendly and appreciative
- Thorough but efficient
- Empathetic to concerns
- Professional

CONVERSATION FLOW:
1. Welcome back and verification
2. Request final photos (exterior + interior)
3. Check for damage or issues
4. Confirm mileage and battery level
5. Calculate any additional charges
6. Process payment if needed
7. Thank customer and request review
8. Lock vehicle

Available functions:
- verify_booking(confirmation_code)
- request_final_photos(booking_id, phone_number)
- check_damage(booking_id, photos)
- calculate_charges(booking_id, mileage, battery)
- lock_vehicle(vehicle_id)
- send_receipt(customer_email)

CRITICAL: Always document any damage or issues. Be empathetic but clear about additional charges.`
      }
    ]
  },
  voice: {
    provider: 'elevenlabs',
    voiceId: 'EXAVITQu4vr4xnSDxMaL'
  },
  functions: [
    // Similar function definitions as check-in
  ]
};

async function setupAssistants() {
  try {
    const checkinResult = await vapi.createAssistant(checkinAssistant);
    console.log('Check-in assistant created:', checkinResult.id);
    
    const checkoutResult = await vapi.createAssistant(checkoutAssistant);
    console.log('Check-out assistant created:', checkoutResult.id);
    
    // Save IDs to environment
    console.log('\nAdd these to your .env file:');
    console.log(`VAPI_CHECKIN_ASSISTANT_ID=${checkinResult.id}`);
    console.log(`VAPI_CHECKOUT_ASSISTANT_ID=${checkoutResult.id}`);
  } catch (error) {
    console.error('Error setting up assistants:', error);
  }
}

setupAssistants();
```

### 9.2 Voice Agent Function Handlers

```typescript
// services/voice-service/src/handlers/FunctionHandlers.ts

import { TeslaAPIClient } from '../clients/TeslaAPIClient';
import { BookingRepository } from '../repositories/BookingRepository';
import { TwilioClient } from '../clients/TwilioClient';

export class VapiFunctionHandlers {
  private tesla: TeslaAPIClient;
  private bookings: BookingRepository;
  private twilio: TwilioClient;

  constructor() {
    this.tesla = new TeslaAPIClient(process.env.TESLA_API_TOKEN!);
    this.bookings = new BookingRepository();
    this.twilio = new TwilioClient(
      process.env.TWILIO_ACCOUNT_SID!,
      process.env.TWILIO_AUTH_TOKEN!,
      process.env.TWILIO_PHONE_NUMBER!
    );
  }

  async handleFunctionCall(functionName: string, parameters: any): Promise<any> {
    switch (functionName) {
      case 'verify_booking':
        return await this.verifyBooking(parameters.confirmation_code);
      
      case 'send_sms':
        return await this.sendSMS(parameters.phone_number, parameters.message);
      
      case 'request_photos':
        return await this.requestPhotos(parameters.booking_id, parameters.phone_number);
      
      case 'unlock_vehicle':
        return await this.unlockVehicle(parameters.vehicle_id);
      
      case 'lock_vehicle':
        return await this.lockVehicle(parameters.vehicle_id);
      
      case 'check_damage':
        return await this.checkDamage(parameters.booking_id, parameters.photos);
      
      default:
        throw new Error(`Unknown function: ${functionName}`);
    }
  }

  private async verifyBooking(confirmationCode: string) {
    const booking = await this.bookings.findByConfirmationCode(confirmationCode);
    
    if (!booking) {
      return {
        success: false,
        message: 'Booking not found. Please check your confirmation code.'
      };
    }

    return {
      success: true,
      booking: {
        customer_name: `${booking.customer.firstName} ${booking.customer.lastName}`,
        vehicle: `${booking.vehicle.year} ${booking.vehicle.model}`,
        license_plate: booking.vehicle.licensePlate,
        parking_spot: booking.vehicle.homeLocation,
        tour_package: booking.tourPackage?.name || 'No tour selected'
      }
    };
  }

  private async sendSMS(phoneNumber: string, message: string) {
    try {
      await this.twilio.sendSMS(phoneNumber, message);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  private async requestPhotos(bookingId: string, phoneNumber: string) {
    const message = `Please text 4 photos of the vehicle to this number:
1. Front view
2. Driver side
3. Rear view
4. Passenger side

Reply with the photos now.`;

    await this.twilio.sendSMS(phoneNumber, message);
    
    return {
      success: true,
      message: 'Photo request sent. Waiting for customer to send photos...'
    };
  }

  private async unlockVehicle(vehicleId: string) {
    try {
      await this.tesla.unlockDoors(vehicleId);
      
      // Log the unlock event
      await this.bookings.logVehicleAccess(vehicleId, 'unlock', 'voice_agent');
      
      return {
        success: true,
        message: 'Vehicle unlocked successfully. Doors will unlock in 5 seconds.'
      };
    } catch (error) {
      return {
        success: false,
        error: 'Failed to unlock vehicle. Please contact support.'
      };
    }
  }

  private async lockVehicle(vehicleId: string) {
    try {
      await this.tesla.lockDoors(vehicleId);
      
      await this.bookings.logVehicleAccess(vehicleId, 'lock', 'voice_agent');
      
      return {
        success: true,
        message: 'Vehicle locked successfully.'
      };
    } catch (error) {
      return {
        success: false,
        error: 'Failed to lock vehicle. Please contact support.'
      };
    }
  }

  private async checkDamage(bookingId: string, photos: string[]) {
    // Use computer vision to analyze photos for damage
    // This would integrate with AWS Rekognition or Google Vision API
    
    // For now, return placeholder
    return {
      success: true,
      damage_detected: false,
      message: 'No visible damage detected. Proceeding with check-out.'
    };
  }
}
```

---

