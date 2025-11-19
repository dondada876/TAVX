# TAV-X - CLAUDE CODE IMPLEMENTATION GUIDE

**Document ID**: CCDEV-001
**Created**: November 18, 2025
**Repository**: https://github.com/YOUR_USERNAME/TAVX
**Status**: Ready for Development

---

## 🎯 PURPOSE

This guide provides Claude Code with everything needed to build the TAV-X platform from scratch. It consolidates the PRD, technical architecture, and implementation priorities into a developer-focused roadmap.

---

## 📖 ESSENTIAL DOCUMENTATION

### Must-Read Documents (in order)

1. **[Implementation Summary](docs/Implementation_Summary.md)** *(5 min read)*
   - Quick overview of the entire system
   - What Claude Code needs beyond the PRD
   - Common pitfalls to avoid

2. **[Product Requirements Document](docs/prd/Initial_PRD.md)** *(30 min read)*
   - Complete business requirements
   - User stories and flows
   - Success metrics and KPIs

3. **[Architecture Part 1](docs/architecture/Architecture_Specification_Part1.md)** *(20 min read)*
   - Database schemas (Airtable + PostgreSQL)
   - Core API specifications
   - External API integrations (Tesla, Vapi, Stripe)

4. **[Architecture Part 2](docs/architecture/Architecture_Specification_Part2.md)** *(20 min read)*
   - Infrastructure and deployment
   - Testing strategies
   - Monitoring and observability

5. **[Architecture Part 3](docs/architecture/Architecture_Specification_Part3.md)** *(20 min read)*
   - Tour engine implementation
   - Mobile app architecture
   - Final deployment details

**Total Reading Time**: ~90 minutes

---

## 🏗️ SYSTEM OVERVIEW

### What We're Building

**TAV-X** = Tesla rental platform + GPS historical tours + AI automation

**Core User Flows:**
1. Customer books Tesla online → Receives confirmation
2. Day of rental → Calls AI agent → Completes check-in via voice (5 min)
3. In vehicle → Tablet app guides historical tour with GPS-triggered audio
4. End of rental → Voice check-out → Automated billing and partner payouts

### Technology Decisions

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **Backend** | Node.js + TypeScript + Express | Industry standard, great ecosystem |
| **Database** | PostgreSQL (Airtable for MVP) | Scalable, reliable, good TS support |
| **Cache** | Redis | Fast, simple, proven |
| **Queue** | RabbitMQ | Reliable message delivery |
| **Voice AI** | Vapi | Best-in-class voice agent platform |
| **Vehicle Control** | Tesla Official API | Direct integration, full control |
| **Tours** | VoiceMap | Proven GPS tour platform |
| **Payments** | Stripe | Industry leader, great docs |
| **Mobile** | React Native + Expo | Cross-platform, fast development |
| **Infrastructure** | AWS + Kubernetes | Scalable, enterprise-grade |

---

## 🚀 IMPLEMENTATION PHASES

### Phase 1: MVP Foundation (Weeks 1-4)

**Goal**: Prove the core concept with 10 pilot vehicles and 1 tour route

#### Week 1: Setup & Authentication
- [ ] Initialize monorepo with services
- [ ] Set up PostgreSQL + Redis + RabbitMQ (Docker)
- [ ] Implement JWT authentication service
- [ ] Create API gateway with Kong
- [ ] Set up CI/CD pipeline (GitHub Actions)

#### Week 2: Booking System
- [ ] WordPress + WooCommerce installation
- [ ] Custom booking plugin development
- [ ] Airtable database setup
- [ ] Stripe payment integration
- [ ] Email/SMS confirmation (Twilio)

#### Week 3: Voice Check-In
- [ ] Vapi account setup and assistant configuration
- [ ] Build function handlers for vehicle control
- [ ] Implement photo upload via MMS
- [ ] Tesla API integration for unlock/lock
- [ ] Computer vision for damage detection (AWS Rekognition)

#### Week 4: Tour Engine
- [ ] VoiceMap account and first tour creation
- [ ] React Native tablet app skeleton
- [ ] GPS tracking with geofencing
- [ ] Audio playback system
- [ ] Offline content management

**Deliverables**:
- ✅ Booking system accepting reservations
- ✅ Voice check-in working end-to-end
- ✅ 1 tour route (Oakland Heritage) operational
- ✅ 10 vehicles equipped with tablets
- ✅ Operations dashboard (basic)

---

### Phase 2: Scale Operations (Weeks 5-8)

**Goal**: Scale to 30 vehicles, add features, improve automation

#### Week 5: Additional Tours
- [ ] Black Panther Party Historical Tour content + VoiceMap
- [ ] Bay Area Scenic Tour content + VoiceMap
- [ ] Tour selection UI in tablet app
- [ ] Analytics on tour completion rates

#### Week 6: Partner Portal
- [ ] Partner dashboard (Retool or React)
- [ ] Automated revenue split calculations
- [ ] Monthly statement generation (PDF)
- [ ] ACH payment integration

#### Week 7: Operations Automation
- [ ] Fleet management dashboard enhancements
- [ ] Maintenance queue and task assignment
- [ ] Battery monitoring and alerts
- [ ] Slack integration for notifications

#### Week 8: Testing & Optimization
- [ ] Load testing (k6)
- [ ] Performance optimization
- [ ] Bug fixes and polish
- [ ] User acceptance testing

**Deliverables**:
- ✅ 3 tour routes live
- ✅ 30 vehicles operational
- ✅ Partner portal with automated payouts
- ✅ Advanced analytics in place
- ✅ Philippines VA team onboarded

---

### Phase 3: Enterprise Features (Weeks 9-12)

**Goal**: Prepare for 100-vehicle fleet and expansion

#### Week 9: Customer Mobile App
- [ ] Customer-facing mobile app (React Native)
- [ ] Booking from mobile
- [ ] Digital key management
- [ ] In-app tour controls

#### Week 10: Integrations
- [ ] Hotel concierge API
- [ ] Expedia/Viator integration
- [ ] Custom tours API for partners
- [ ] White-label booking widget

#### Week 11: Advanced AI
- [ ] Conversational tour guide (upgrade from VoiceMap)
- [ ] Personalized recommendations
- [ ] Dynamic routing based on interests
- [ ] Voice-activated vehicle controls

#### Week 12: Expansion Prep
- [ ] Multi-city support in database
- [ ] Franchise management tools
- [ ] Complete API documentation
- [ ] Franchise playbook

**Deliverables**:
- ✅ 100 vehicles managed
- ✅ Customer mobile app launched
- ✅ OTA partnerships live
- ✅ Ready for San Francisco expansion

---

## 🔧 CRITICAL IMPLEMENTATION DETAILS

### 1. Voice Check-In Flow (Vapi)

**Setup Steps:**
1. Create Vapi account at vapi.ai
2. Create two assistants:
   - `check-in-assistant`: Handles pickup
   - `check-out-assistant`: Handles return
3. Configure function handlers:
   - `verifyBooking(confirmationCode)`: Look up in DB
   - `uploadDriverLicense(imageUrl)`: Store in S3 + verify
   - `recordInspection(photos)`: Save + run damage detection
   - `unlockVehicle(vehicleId)`: Call Tesla API
4. Set up webhooks to receive call events

**Code Example** (see `docs/architecture/Architecture_Specification_Part1.md` Section 4.2)

---

### 2. Tesla API Integration

**Authentication:**
- Use OAuth 2.0 flow
- Store tokens in database (encrypted)
- Implement token refresh logic

**Key Endpoints:**
- `POST /api/1/vehicles/{id}/command/door_unlock`: Unlock vehicle
- `POST /api/1/vehicles/{id}/command/door_lock`: Lock vehicle
- `GET /api/1/vehicles/{id}/data_request/vehicle_state`: Get battery, odometer
- `GET /api/1/vehicles/{id}/data_request/drive_state`: Get GPS location

**Code Example** (see `docs/architecture/Architecture_Specification_Part1.md` Section 4.1)

---

### 3. GPS Tour Geofencing

**Algorithm:**
```typescript
function checkWaypointProximity(
  currentLat: number,
  currentLng: number,
  waypointLat: number,
  waypointLng: number,
  radiusMeters: number
): boolean {
  const distance = haversineDistance(
    currentLat, currentLng,
    waypointLat, waypointLng
  );
  return distance <= radiusMeters;
}

// If within geofence and not yet triggered
if (checkWaypointProximity(...) && !waypoint.triggered) {
  playAudio(waypoint.audioFileUrl);
  waypoint.triggered = true;
  logWaypointVisit(waypoint.id);
}
```

**Considerations:**
- GPS accuracy: ±5-50 meters
- Use compass bearing to ensure proper direction
- Implement "exit geofence" to reset for return trips
- Handle tunnels/GPS loss gracefully

---

### 4. Database Migration Strategy

**Phase 1 (MVP)**: Airtable
- Quick setup, no code required
- Good for 10-30 vehicles
- API rate limits: 5 requests/second

**Phase 2 (Scale)**: PostgreSQL
- Migrate when > 50 vehicles or > 500 bookings/month
- Use n8n to dual-write during migration
- Validate data consistency before cutover

**Migration Script:**
```bash
npm run migrate:airtable-to-postgres
```

---

### 5. Payment Flow

**Booking Payment:**
1. Customer enters card on booking site
2. Stripe creates `PaymentIntent` with amount
3. Store `payment_intent_id` in database
4. Charge card immediately (not hold)
5. Refund policy: 24 hours before pickup

**Partner Payouts:**
1. Monthly cron job calculates revenue split
2. Create Stripe `Transfer` to partner's connected account
3. Generate PDF statement
4. Email partner with statement + transfer confirmation

**Code Example** (see `docs/architecture/Architecture_Specification_Part1.md` Section 4.4)

---

## 📊 TESTING CHECKLIST

### Unit Tests
- [ ] All service methods have tests
- [ ] 80%+ code coverage
- [ ] Mock external APIs (Tesla, Vapi, Stripe)

### Integration Tests
- [ ] API endpoint tests with real database
- [ ] Booking flow end-to-end
- [ ] Payment processing
- [ ] Voice agent function handlers

### E2E Tests (Cypress)
- [ ] Customer books rental online
- [ ] Voice check-in simulation
- [ ] Tour playback in tablet app
- [ ] Partner views dashboard

### Load Tests (k6)
- [ ] 1000 concurrent booking requests
- [ ] GPS location updates (100 devices × 1 req/sec)
- [ ] API p95 latency < 200ms
- [ ] Database connection pool handling

---

## 🔒 SECURITY CHECKLIST

### Before Production
- [ ] All secrets in AWS Secrets Manager (not .env)
- [ ] API rate limiting enabled
- [ ] HTTPS enforced on all endpoints
- [ ] JWT tokens with short expiration (15 min)
- [ ] Refresh token rotation implemented
- [ ] SQL injection protection (parameterized queries)
- [ ] XSS protection headers
- [ ] CORS configured correctly
- [ ] Role-based access control (RBAC)
- [ ] Audit logs for sensitive operations
- [ ] PII encryption at rest
- [ ] Regular security scans (Snyk, npm audit)

---

## 📈 MONITORING & ALERTS

### Metrics to Track

**System Health:**
- API response times (p50, p95, p99)
- Error rates per endpoint
- Database query performance
- Cache hit rates
- Message queue depth

**Business Metrics:**
- Bookings created per day
- Voice check-in success rate
- Tour completion rate
- Average rental duration
- Revenue per vehicle per day

**Alerts:**
- API error rate > 1%
- Database CPU > 80%
- Voice check-in failure rate > 5%
- Vehicle battery < 20%
- Payment processing failures

**Tools:**
- Prometheus: Metrics collection
- Grafana: Dashboards
- Sentry: Error tracking
- PagerDuty: On-call alerting

---

## 🐛 COMMON PITFALLS

### 1. Tesla API Rate Limiting
**Problem**: Tesla throttles API requests
**Solution**: Cache vehicle state for 5 minutes, use webhooks when available

### 2. GPS Drift in Cities
**Problem**: Tall buildings cause GPS inaccuracy
**Solution**: Use larger geofence radii (100-150m) in downtown areas

### 3. Voice AI Misunderstandings
**Problem**: Vapi doesn't understand customer
**Solution**: Implement "repeat that" and fallback to human operator

### 4. Offline Tour Content
**Problem**: Tablet loses internet during tour
**Solution**: Pre-download all audio files and maps to device storage

### 5. Database Connection Pool Exhaustion
**Problem**: Too many open connections under load
**Solution**: Use connection pooling (pg-pool), set max connections

### 6. Photo Upload Timeouts
**Problem**: MMS photo upload via Twilio is slow
**Solution**: Use asynchronous processing, webhook callback

### 7. Timezone Confusion
**Problem**: Bookings in wrong timezone
**Solution**: Store all times in UTC, convert to local for display

### 8. Partner Revenue Disputes
**Problem**: Partners question revenue calculations
**Solution**: Transparent dashboard showing every booking and split

---

## 📞 EXTERNAL API DOCUMENTATION

### Tesla API
- **Docs**: https://tesla-api.timdorr.com/
- **Community**: https://teslaapi.dev/
- **Rate Limits**: Unclear, be conservative

### Vapi
- **Docs**: https://docs.vapi.ai/
- **Dashboard**: https://dashboard.vapi.ai/
- **Support**: support@vapi.ai

### VoiceMap
- **Docs**: https://www.voicemap.me/publishers
- **Creator Portal**: https://creator.voicemap.me/
- **Support**: publishers@voicemap.me

### Stripe
- **Docs**: https://stripe.com/docs/api
- **Dashboard**: https://dashboard.stripe.com/
- **Connect**: https://stripe.com/docs/connect

### Twilio
- **Docs**: https://www.twilio.com/docs/
- **Console**: https://console.twilio.com/
- **SMS**: https://www.twilio.com/docs/sms

---

## ✅ PRE-LAUNCH CHECKLIST

### Infrastructure
- [ ] Production AWS account set up
- [ ] Kubernetes cluster configured
- [ ] RDS PostgreSQL provisioned
- [ ] ElastiCache Redis provisioned
- [ ] S3 buckets created (media, backups)
- [ ] CloudFront CDN configured
- [ ] Domain DNS configured
- [ ] SSL certificates installed

### Services
- [ ] All microservices deployed
- [ ] API gateway configured
- [ ] Message queue operational
- [ ] Background jobs running (crons)
- [ ] Monitoring stack deployed

### Integrations
- [ ] Tesla API production tokens
- [ ] Vapi assistants published
- [ ] Stripe live keys configured
- [ ] Twilio production number
- [ ] Google Maps API quota increased
- [ ] VoiceMap tours published

### Testing
- [ ] Load tests passed
- [ ] Security scan clean
- [ ] E2E tests green
- [ ] Backup/restore tested
- [ ] Disaster recovery plan documented

### Operations
- [ ] Runbooks created for common issues
- [ ] On-call rotation schedule
- [ ] Support email configured
- [ ] Customer FAQ published
- [ ] Staff training completed

---

## 🎬 GETTING STARTED (RIGHT NOW)

### Immediate Actions

1. **Read Implementation Summary** (5 min)
   ```bash
   cat docs/Implementation_Summary.md
   ```

2. **Set Up Development Environment** (30 min)
   ```bash
   # Clone repo
   git clone [REPO_URL]
   cd TAVX

   # Copy env template
   cp .env.example .env
   # Edit .env with your API keys

   # Start dependencies
   cd infrastructure/docker
   docker-compose up -d
   ```

3. **Initialize Database** (10 min)
   ```bash
   # Create PostgreSQL tables
   npm run db:migrate

   # Seed with test data
   npm run db:seed
   ```

4. **Build First Service** (2 hours)
   ```bash
   # Start with authentication service
   cd services/booking
   npm install
   npm run dev
   ```

5. **Test API** (15 min)
   ```bash
   # Health check
   curl http://localhost:3000/health

   # Create test booking
   curl -X POST http://localhost:3000/api/v1/bookings \
     -H "Content-Type: application/json" \
     -d '{"vehicleId": "test123", "pickupDate": "2025-11-25"}'
   ```

---

## 🎯 SUCCESS DEFINITION

**MVP is complete when:**

- ✅ Customer can book online and pay
- ✅ Customer receives SMS confirmation
- ✅ Customer completes voice check-in in < 5 min
- ✅ Vehicle unlocks automatically after check-in
- ✅ Tablet app plays tour audio at waypoints
- ✅ Customer completes voice check-out
- ✅ Fleet dashboard shows real-time vehicle status
- ✅ Partner portal shows revenue and bookings
- ✅ All core features tested and working
- ✅ System handles 10 concurrent rentals

**Ready for production when:**

- ✅ 100 test bookings completed successfully
- ✅ Load tests show system handles 1000 concurrent users
- ✅ Security audit passed
- ✅ Monitoring and alerting operational
- ✅ Documentation complete
- ✅ Team trained on operations
- ✅ Backup and disaster recovery tested

---

## 🚀 LET'S BUILD!

You now have everything you need to build TAV-X from the ground up. The architecture is solid, the requirements are clear, and the roadmap is defined.

**Start with Week 1, Task 1**: Initialize monorepo with services

**Questions?** Review the architecture documents or check the implementation summary.

**Good luck, and let's revolutionize Tesla rentals!** 🚗⚡

---

**Document Status**: Complete - Ready for Development
**Last Updated**: November 18, 2025
