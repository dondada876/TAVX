# TAV-X Complete Technical Architecture Specification
## System Build Guide for Claude Code

**Version:** 2.0  
**Date:** November 18, 2025  
**Purpose:** Complete technical specification for building the TAV-X rental and tour operating system

---

## Executive Summary

This document provides Claude Code with everything needed to architect and build the complete TAV-X system: a comprehensive Tesla rental and AI-guided tour platform operating in Oakland, CA. The system handles:

- Customer booking and payment processing
- Voice-guided vehicle check-in/check-out
- GPS-triggered historical tours with audio narration
- Real-time fleet management and tracking
- Partner revenue management and payouts
- Complete operational analytics

**Technology Foundation:**
- Node.js/TypeScript backend with microservices
- React/React Native for web and mobile
- Airtable (Phase 1) → PostgreSQL (Phase 2) for data
- Real-time updates via WebSocket
- AI voice agents via Vapi
- Tesla API for vehicle control

---

## 1. ADDITIONAL ARCHITECTURE REQUIREMENTS

Beyond the PRD, here are critical technical specifications Claude Code needs:

### 1.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      INTERNET & EXTERNAL APIS                    │
│  (Stripe, Tesla API, Twilio, Vapi, Google Maps, VoiceMap)      │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                       API GATEWAY (Kong)                         │
│              Rate Limiting | Auth | Routing | Logging            │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌────────▼────────┐  ┌──────▼──────┐
│   Customer     │  │   Operator      │  │   Partner   │
│   Web Portal   │  │   Dashboard     │  │   Portal    │
│  (WordPress)   │  │   (React/Retool)│  │   (React)   │
└───────┬────────┘  └────────┬────────┘  └──────┬──────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    BACKEND SERVICES (Node.js)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Booking  │  │ Vehicle  │  │  Tour    │  │ Payment  │       │
│  │ Service  │  │ Service  │  │ Service  │  │ Service  │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
│       │             │              │              │             │
│  ┌────▼─────┐  ┌───▼──────┐  ┌───▼──────┐  ┌───▼──────┐      │
│  │   CRM    │  │   AI     │  │ Partner  │  │ Analytics│      │
│  │ Service  │  │  Voice   │  │  Mgmt    │  │ Service  │      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
└───────┼─────────────┼─────────────┼─────────────┼─────────────┘
        │             │              │              │
┌───────▼─────────────▼──────────────▼──────────────▼─────────────┐
│                    MESSAGE QUEUE (RabbitMQ)                      │
│           Event Bus for Async Processing & Notifications        │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                         DATA LAYER                               │
│  ┌──────────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  PostgreSQL  │  │  Redis   │  │  Qdrant  │  │  S3      │    │
│  │  (Primary)   │  │  (Cache) │  │ (Vector) │  │  (Files) │    │
│  └──────────────┘  └──────────┘  └──────────┘  └──────────┘    │
└──────────────────────────────────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                    AUTOMATION & JOBS                             │
│            n8n Workflows | Cron Jobs | Background Workers        │
└──────────────────────────────────────────────────────────────────┘
```

### 1.2 Data Flow Architecture

**Critical Path: Customer Booking to Tour Completion**

```
1. BOOKING FLOW
   Customer → Web Portal → API Gateway → Booking Service
   ↓
   Check Availability (Query Cache → Database)
   ↓
   Create Payment Intent (Stripe API)
   ↓
   Reserve Vehicle (Write to DB + Redis Lock)
   ↓
   Send Confirmation (Queue → Notification Service → Twilio/Email)
   ↓
   Update Dashboard (WebSocket broadcast)

2. CHECK-IN FLOW
   Customer Arrives → Calls Phone Number → Twilio → Vapi AI
   ↓
   AI Agent verifies booking (API call to Booking Service)
   ↓
   Guide inspection (Voice prompts)
   ↓
   Request Photos → SMS → S3 Upload → Computer Vision Analysis
   ↓
   Unlock Vehicle (Tesla API call)
   ↓
   Log Check-in (Database + Audit Trail)
   ↓
   Notify Operations (Slack notification)

3. TOUR FLOW
   Customer Opens Tablet → Loads Tour → GPS Tracking Starts
   ↓
   Location Updates (Every 10 seconds) → Check Waypoint Proximity
   ↓
   Trigger Audio (Within geofence) → Play Narration
   ↓
   Log Progress (Local + Sync to API)
   ↓
   Complete Tour → Rate Experience → Upload Session Data

4. CHECK-OUT FLOW
   Customer Returns → Calls Check-out Line → Vapi AI
   ↓
   Final Photos + Inspection
   ↓
   Calculate Mileage/Battery
   ↓
   Process Payment (if additional charges)
   ↓
   Lock Vehicle (Tesla API)
   ↓
   Generate Receipt
   ↓
   Calculate Partner Revenue Split
   ↓
   Request Review
```

---

## 2. DATABASE SCHEMAS & RELATIONSHIPS

### 2.1 Entity Relationship Diagram

```
USERS (1) ──────────────────────────────── (M) BOOKINGS
  │                                             │
  │                                             │
  ├── (1:1) CUSTOMERS                           ├── (M:1) VEHICLES
  │          ├── drivers_license                │          ├── owner_partner
  │          ├── stripe_customer_id             │          ├── tesla_api_token
  │          └── referral_code                  │          └── current_status
  │                                             │
  ├── (1:1) PARTNERS                            ├── (M:1) TOUR_PACKAGES
  │          ├── revenue_split                  │          ├── tour_route
  │          ├── payment_method                 │          └── price
  │          └── tier                           │
  │                                             ├── (1:M) PAYMENTS
  └── (1:1) STAFF                               │          ├── stripe_payment_id
                                                │          └── status
                                                │
                                                ├── (1:M) INSPECTION_LOGS
                                                │          ├── photos
                                                │          ├── odometer
                                                │          └── damage_notes
                                                │
                                                └── (1:1) TOUR_SESSIONS
                                                           ├── gps_trace
                                                           ├── waypoints_visited
                                                           └── completion_rate

TOUR_ROUTES (1) ──────────────── (M) WAYPOINTS
                                       ├── latitude/longitude
                                       ├── narration_audio_url
                                       ├── geofence_radius
                                       └── sequence

VEHICLES (1) ────────────────────── (M) MAINTENANCE_LOGS
        └── (1:M) PHOTOS
```

### 2.2 Critical Indexes

```sql
-- Performance-critical indexes for PostgreSQL

-- Booking queries (most frequent)
CREATE INDEX CONCURRENTLY idx_bookings_dates 
  ON bookings(pickup_datetime, return_datetime) 
  WHERE status NOT IN ('cancelled', 'completed');

CREATE INDEX CONCURRENTLY idx_bookings_vehicle_dates 
  ON bookings(vehicle_id, pickup_datetime, return_datetime)
  WHERE status IN ('confirmed', 'in_progress');

-- Vehicle availability lookups
CREATE INDEX CONCURRENTLY idx_vehicles_status_location 
  ON vehicles(current_status, home_location) 
  WHERE current_status = 'available';

-- Geospatial queries for tour tracking
CREATE INDEX CONCURRENTLY idx_waypoints_location 
  ON waypoints USING GIST (
    point(longitude, latitude)
  );

-- Customer lookup optimizations
CREATE INDEX CONCURRENTLY idx_customers_email 
  ON customers(LOWER(email));

CREATE INDEX CONCURRENTLY idx_customers_phone 
  ON customers(phone) 
  WHERE phone IS NOT NULL;

-- Payment reconciliation
CREATE INDEX CONCURRENTLY idx_payments_date_status 
  ON payments(transaction_date DESC, status);

-- Partner reporting
CREATE INDEX CONCURRENTLY idx_bookings_partner_revenue 
  ON bookings(vehicle_id) 
  INCLUDE (total_price, created_at) 
  WHERE status = 'completed';

-- Real-time dashboard queries
CREATE INDEX CONCURRENTLY idx_vehicles_realtime 
  ON vehicles(current_status, current_battery_percent, updated_at DESC);
```

---

## 3. API SPECIFICATIONS

### 3.1 REST API Endpoints (OpenAPI/Swagger)

```yaml
openapi: 3.0.0
info:
  title: TAV-X API
  version: 1.0.0
  description: Tesla rental and tour management API

servers:
  - url: https://api.tavx.com/v1
    description: Production
  - url: https://staging-api.tavx.com/v1
    description: Staging

paths:
  /auth/register:
    post:
      summary: Register new customer
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [email, password, firstName, lastName, phone]
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
                  minLength: 8
                firstName:
                  type: string
                lastName:
                  type: string
                phone:
                  type: string
      responses:
        201:
          description: User created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AuthResponse'

  /auth/login:
    post:
      summary: Login user
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [email, password]
              properties:
                email:
                  type: string
                password:
                  type: string
      responses:
        200:
          description: Login successful
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AuthResponse'

  /vehicles/availability:
    get:
      summary: Check vehicle availability
      parameters:
        - name: startDate
          in: query
          required: true
          schema:
            type: string
            format: date-time
        - name: endDate
          in: query
          required: true
          schema:
            type: string
            format: date-time
        - name: vehicleType
          in: query
          schema:
            type: string
            enum: [Model 3, Model Y, Model S, Model X]
      responses:
        200:
          description: Available vehicles
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Vehicle'

  /bookings:
    post:
      summary: Create new booking
      security:
        - bearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/BookingCreate'
      responses:
        201:
          description: Booking created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Booking'

  /bookings/{confirmationCode}:
    get:
      summary: Get booking by confirmation code
      parameters:
        - name: confirmationCode
          in: path
          required: true
          schema:
            type: string
      responses:
        200:
          description: Booking details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Booking'

  /bookings/{bookingId}/checkin:
    post:
      summary: Start check-in process
      security:
        - bearerAuth: []
      parameters:
        - name: bookingId
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        200:
          description: Check-in initiated
          content:
            application/json:
              schema:
                type: object
                properties:
                  callId:
                    type: string
                  status:
                    type: string

  /bookings/{bookingId}/checkin/complete:
    post:
      summary: Complete check-in
      security:
        - bearerAuth: []
      parameters:
        - name: bookingId
          in: path
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [odometerReading, batteryLevel, photos]
              properties:
                odometerReading:
                  type: integer
                batteryLevel:
                  type: integer
                  minimum: 0
                  maximum: 100
                photos:
                  type: array
                  items:
                    type: string
                    format: uri
                damageNotes:
                  type: string
      responses:
        200:
          description: Check-in completed

  /tours:
    get:
      summary: List available tour packages
      responses:
        200:
          description: Tour packages
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/TourPackage'

  /tours/{tourId}:
    get:
      summary: Get tour details with waypoints
      parameters:
        - name: tourId
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        200:
          description: Tour details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TourDetails'

  /tours/sessions:
    post:
      summary: Start tour session
      security:
        - bearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [bookingId, tourId]
              properties:
                bookingId:
                  type: string
                  format: uuid
                tourId:
                  type: string
                  format: uuid
      responses:
        201:
          description: Tour session started

  /tours/sessions/{sessionId}/waypoint:
    post:
      summary: Log waypoint visit
      security:
        - bearerAuth: []
      parameters:
        - name: sessionId
          in: path
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [waypointId, timestamp, location]
              properties:
                waypointId:
                  type: string
                  format: uuid
                timestamp:
                  type: string
                  format: date-time
                location:
                  type: object
                  properties:
                    latitude:
                      type: number
                    longitude:
                      type: number
      responses:
        200:
          description: Waypoint logged

  /webhooks/stripe:
    post:
      summary: Stripe webhook handler
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        200:
          description: Webhook processed

  /webhooks/twilio:
    post:
      summary: Twilio webhook handler
      requestBody:
        content:
          application/x-www-form-urlencoded:
            schema:
              type: object
      responses:
        200:
          description: Webhook processed

  /webhooks/vapi:
    post:
      summary: Vapi voice AI webhook
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        200:
          description: Webhook processed

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    AuthResponse:
      type: object
      properties:
        success:
          type: boolean
        data:
          type: object
          properties:
            token:
              type: string
            user:
              $ref: '#/components/schemas/User'

    User:
      type: object
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
        firstName:
          type: string
        lastName:
          type: string
        role:
          type: string
          enum: [customer, staff, partner, admin]

    Vehicle:
      type: object
      properties:
        id:
          type: string
          format: uuid
        vin:
          type: string
        model:
          type: string
        year:
          type: integer
        color:
          type: string
        fsdEnabled:
          type: boolean
        currentStatus:
          type: string
        pricePerDay:
          type: number

    BookingCreate:
      type: object
      required: [vehicleId, pickupDatetime, returnDatetime]
      properties:
        vehicleId:
          type: string
          format: uuid
        pickupDatetime:
          type: string
          format: date-time
        returnDatetime:
          type: string
          format: date-time
        tourPackageId:
          type: string
          format: uuid
        promoCode:
          type: string
        addons:
          type: array
          items:
            type: string

    Booking:
      type: object
      properties:
        id:
          type: string
          format: uuid
        confirmationCode:
          type: string
        status:
          type: string
        vehicle:
          $ref: '#/components/schemas/Vehicle'
        pickupDatetime:
          type: string
          format: date-time
        returnDatetime:
          type: string
          format: date-time
        totalPrice:
          type: number

    TourPackage:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        description:
          type: string
        durationMinutes:
          type: integer
        price:
          type: number
        thumbnail:
          type: string
          format: uri

    TourDetails:
      allOf:
        - $ref: '#/components/schemas/TourPackage'
        - type: object
          properties:
            waypoints:
              type: array
              items:
                $ref: '#/components/schemas/Waypoint'

    Waypoint:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        sequence:
          type: integer
        latitude:
          type: number
        longitude:
          type: number
        geofenceRadius:
          type: integer
        narrationAudioUrl:
          type: string
          format: uri
        description:
          type: string
```

---

## 4. MICROSERVICES ARCHITECTURE

### 4.1 Service Breakdown

**Booking Service**
```typescript
// services/booking-service/src/index.ts

import express from 'express';
import { BookingController } from './controllers/BookingController';
import { BookingRepository } from './repositories/BookingRepository';
import { VehicleService } from './external/VehicleService';
import { PaymentService } from './external/PaymentService';

const app = express();
const repository = new BookingRepository();
const vehicleService = new VehicleService();
const paymentService = new PaymentService();
const controller = new BookingController(repository, vehicleService, paymentService);

app.post('/bookings', controller.create.bind(controller));
app.get('/bookings/:id', controller.getById.bind(controller));
app.put('/bookings/:id', controller.update.bind(controller));
app.delete('/bookings/:id', controller.cancel.bind(controller));

app.listen(3001, () => {
  console.log('Booking Service running on port 3001');
});
```

**Vehicle Service**
```typescript
// services/vehicle-service/src/index.ts

import express from 'express';
import { VehicleController } from './controllers/VehicleController';
import { TeslaAPIClient } from './clients/TeslaAPIClient';
import { WebSocketServer } from 'ws';

const app = express();
const teslaClient = new TeslaAPIClient();
const controller = new VehicleController(teslaClient);

// REST endpoints
app.get('/vehicles', controller.list.bind(controller));
app.get('/vehicles/:id', controller.getById.bind(controller));
app.post('/vehicles/:id/unlock', controller.unlock.bind(controller));
app.post('/vehicles/:id/lock', controller.lock.bind(controller));
app.get('/vehicles/:id/status', controller.getStatus.bind(controller));

// WebSocket for real-time location updates
const wss = new WebSocketServer({ port: 3002 });

wss.on('connection', (ws) => {
  console.log('Client connected for vehicle updates');
  
  // Subscribe to vehicle updates
  ws.on('message', (message) => {
    const { vehicleId } = JSON.parse(message.toString());
    // Start streaming vehicle data
  });
});

app.listen(3003, () => {
  console.log('Vehicle Service running on port 3003');
});
```

**Tour Service**
```typescript
// services/tour-service/src/index.ts

import express from 'express';
import { TourController } from './controllers/TourController';
import { VoiceMapClient } from './clients/VoiceMapClient';
import { LocationTracker } from './services/LocationTracker';

const app = express();
const voiceMapClient = new VoiceMapClient();
const locationTracker = new LocationTracker();
const controller = new TourController(voiceMapClient, locationTracker);

app.get('/tours', controller.list.bind(controller));
app.get('/tours/:id', controller.getById.bind(controller));
app.post('/tours/sessions', controller.startSession.bind(controller));
app.post('/tours/sessions/:id/waypoint', controller.logWaypoint.bind(controller));
app.post('/tours/sessions/:id/complete', controller.completeSession.bind(controller));

app.listen(3004, () => {
  console.log('Tour Service running on port 3004');
});
```

### 4.2 Service Communication

```typescript
// shared/message-queue/EventBus.ts

import amqp from 'amqplib';

export class EventBus {
  private connection: amqp.Connection;
  private channel: amqp.Channel;

  async connect() {
    this.connection = await amqp.connect(process.env.RABBITMQ_URL!);
    this.channel = await this.connection.createChannel();
  }

  async publish(exchange: string, routingKey: string, message: any) {
    await this.channel.assertExchange(exchange, 'topic', { durable: true });
    this.channel.publish(
      exchange,
      routingKey,
      Buffer.from(JSON.stringify(message)),
      { persistent: true }
    );
  }

  async subscribe(exchange: string, routingKey: string, handler: (msg: any) => void) {
    await this.channel.assertExchange(exchange, 'topic', { durable: true });
    const queue = await this.channel.assertQueue('', { exclusive: true });
    
    await this.channel.bindQueue(queue.queue, exchange, routingKey);
    
    this.channel.consume(queue.queue, async (msg) => {
      if (msg) {
        const content = JSON.parse(msg.content.toString());
        await handler(content);
        this.channel.ack(msg);
      }
    });
  }
}

// Event types
export const Events = {
  BOOKING_CREATED: 'booking.created',
  BOOKING_CONFIRMED: 'booking.confirmed',
  BOOKING_CANCELLED: 'booking.cancelled',
  CHECKIN_STARTED: 'checkin.started',
  CHECKIN_COMPLETED: 'checkin.completed',
  CHECKOUT_COMPLETED: 'checkout.completed',
  VEHICLE_UNLOCKED: 'vehicle.unlocked',
  VEHICLE_LOCKED: 'vehicle.locked',
  TOUR_STARTED: 'tour.started',
  TOUR_WAYPOINT_REACHED: 'tour.waypoint.reached',
  TOUR_COMPLETED: 'tour.completed',
  PAYMENT_SUCCESS: 'payment.success',
  PAYMENT_FAILED: 'payment.failed'
};
```

---

## 5. SECURITY & AUTHENTICATION

### 5.1 JWT Authentication

```typescript
// middleware/auth.ts

import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
  };
}

export const authMiddleware = (req: AuthRequest, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

export const requireRole = (roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    next();
  };
};

// Usage
app.post('/bookings', authMiddleware, bookingController.create);
app.get('/admin/reports', authMiddleware, requireRole(['admin', 'staff']), reportsController.generate);
```

### 5.2 Data Encryption

```typescript
// utils/encryption.ts

import crypto from 'crypto';

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY!; // Must be 32 bytes
const IV_LENGTH = 16;

export function encrypt(text: string): string {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY, 'hex'), iv);
  let encrypted = cipher.update(text);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  return iv.toString('hex') + ':' + encrypted.toString('hex');
}

export function decrypt(text: string): string {
  const parts = text.split(':');
  const iv = Buffer.from(parts.shift()!, 'hex');
  const encryptedText = Buffer.from(parts.join(':'), 'hex');
  const decipher = crypto.createDecipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY, 'hex'), iv);
  let decrypted = decipher.update(encryptedText);
  decrypted = Buffer.concat([decrypted, decipher.final()]);
  return decrypted.toString();
}

// Usage: Encrypt sensitive data before storing
import { encrypt, decrypt } from './utils/encryption';

const driversLicense = '12345678';
const encrypted = encrypt(driversLicense);
// Store encrypted in database

// When retrieving
const decrypted = decrypt(encrypted);
```

### 5.3 Rate Limiting

```typescript
// middleware/rateLimiter.ts

import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

// General API rate limit
export const apiLimiter = rateLimit({
  store: new RedisStore({
    client: redis,
    prefix: 'rl:api:'
  }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});

// Strict limiter for auth endpoints
export const authLimiter = rateLimit({
  store: new RedisStore({
    client: redis,
    prefix: 'rl:auth:'
  }),
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts'
});

// Usage
app.use('/api/', apiLimiter);
app.use('/api/auth/login', authLimiter);
```

---

