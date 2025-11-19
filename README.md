# TAV-X - Tesla Autonomous Tour & Rental Platform

**Autonomous Vehicle Tours + AI-Powered Fleet Management**

> Revolutionary Tesla rental platform with GPS-guided historical tours, voice-activated check-in, and automated fleet operations

[![Status](https://img.shields.io/badge/Status-In%20Development-yellow)]()
[![Version](https://img.shields.io/badge/Version-1.0.0--alpha-blue)]()
[![License](https://img.shields.io/badge/License-Proprietary-red)]()

---

## 🎯 What is TAV-X?

TAV-X (Tesla Autonomous Vehicle - Experience) is a comprehensive operating system for Tesla rental and guided tour operations. It combines cutting-edge AI technology with rich historical content to deliver an unparalleled customer experience while maximizing fleet efficiency.

### Core Innovation

Replace traditional rental counter check-ins with **AI voice agents**, turn vehicles into **mobile tour guides**, and provide **complete operational visibility** through real-time dashboards.

---

## 🚀 Key Features

### 1. AI Voice-Guided Check-In (Vapi Integration)
- **Zero-wait check-in**: Customers call a number and complete the entire process in 5 minutes
- **Automated verification**: Driver's license via SMS photo upload with computer vision
- **Vehicle inspection**: Voice-guided walkthrough with photo documentation
- **Instant unlock**: Tesla API triggers vehicle access upon completion
- **Damage detection**: AI-powered image analysis flags issues automatically

### 2. GPS Historical Tours
- **Location-triggered narration**: Professional audio plays automatically at waypoints
- **Multiple tour routes**:
  - Oakland Heritage Tour (1 hour)
  - Black Panther Party History (2 hours)
  - Bay Area Scenic Tour (4 hours)
  - Custom Full-Day Experiences (8 hours)
- **Offline capability**: All content pre-downloaded to in-vehicle tablets
- **Multi-language support**: English, Spanish, Mandarin (planned)
- **Progress tracking**: Analytics on completion rates and engagement

### 3. Fleet Management Dashboard
- **Real-time vehicle tracking**: See all Teslas on a live map
- **Status monitoring**: Available, Rented, Maintenance, Issue Reported
- **Battery management**: Track charge levels, optimize charging schedules
- **Maintenance queue**: Automated task assignment to VAs
- **Revenue analytics**: Per-vehicle performance and trend analysis

### 4. Partner Portal
- **Investor dashboard**: Real-time earnings for fleet partners
- **Vehicle performance metrics**: Utilization, revenue, customer ratings
- **Automated statements**: Monthly reports with revenue splits
- **Growth tools**: ROI calculators for fleet expansion

### 5. Complete Booking System
- **WordPress + WooCommerce**: Familiar, robust e-commerce platform
- **Dynamic pricing**: Adjust rates based on demand and seasonality
- **Tour packages**: Rental-only or bundled with tour experiences
- **Instant confirmation**: Automated SMS/email with all details
- **Payment processing**: Stripe integration with deposits and add-ons

---

## 📁 Repository Structure

```
TAVX/
├── docs/                          # Complete documentation
│   ├── prd/                       # Product requirements
│   │   └── Initial_PRD.md         # Master PRD document
│   ├── architecture/              # Technical architecture
│   │   ├── Architecture_Specification_Part1.md
│   │   ├── Architecture_Specification_Part2.md
│   │   └── Architecture_Specification_Part3.md
│   ├── guides/                    # Setup and user guides
│   ├── api/                       # API documentation
│   └── Implementation_Summary.md  # Quick reference
│
├── services/                      # Microservices
│   ├── booking/                   # Booking management service
│   ├── vehicle/                   # Vehicle control & telemetry
│   ├── tour/                      # GPS tour engine
│   ├── payment/                   # Stripe integration
│   ├── voice/                     # Vapi voice AI handlers
│   └── shared/                    # Shared utilities & types
│
├── mobile-app/                    # React Native tablet app
│   ├── src/                       # App source code
│   └── assets/                    # Images, audio files
│
├── web-portal/                    # WordPress customer portal
│   ├── themes/                    # Custom theme
│   └── plugins/                   # Custom booking plugin
│
├── infrastructure/                # Infrastructure as code
│   ├── terraform/                 # AWS resource definitions
│   ├── k8s/                       # Kubernetes manifests
│   ├── docker/                    # Docker configurations
│   └── scripts/                   # Deployment automation
│
├── tests/                         # Test suites
│   ├── unit/                      # Unit tests
│   ├── integration/               # Integration tests
│   └── e2e/                       # End-to-end tests
│
├── .gitignore                     # Git ignore rules
├── README.md                      # This file
└── LICENSE                        # License information
```

---

## 🏗️ System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Customer Layer                        │
│  [Web Booking] [Mobile App] [Voice Check-In] [SMS/Email]│
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                   API Gateway (Kong)                     │
│           Authentication, Rate Limiting, Routing         │
└──────────────────────────┬──────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼───────┐  ┌───────▼───────┐  ┌──────▼──────┐
│   Booking     │  │    Vehicle    │  │    Tour     │
│   Service     │  │    Service    │  │   Service   │
└───────┬───────┘  └───────┬───────┘  └──────┬──────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼───────┐  ┌───────▼───────┐  ┌──────▼──────┐
│   PostgreSQL  │  │     Redis     │  │   Qdrant    │
│   (Core DB)   │  │    (Cache)    │  │ (Vector DB) │
└───────────────┘  └───────────────┘  └─────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼───────┐  ┌───────▼───────┐  ┌──────▼──────┐
│  Tesla API    │  │  Vapi (Voice) │  │  Twilio     │
│ (Vehicle Ctrl)│  │   (Check-In)  │  │  (SMS/MMS)  │
└───────────────┘  └───────────────┘  └─────────────┘
```

### Data Flow: Booking to Check-In

```
1. Customer books on website
   ↓
2. WordPress → Airtable/PostgreSQL
   ↓
3. n8n automation triggered
   ↓
4. Stripe processes payment
   ↓
5. SMS confirmation sent (Twilio)
   ↓
6. Day of rental: reminder SMS
   ↓
7. Customer calls check-in number
   ↓
8. Vapi voice agent guides process
   ↓
9. Photos uploaded via MMS
   ↓
10. Computer vision checks for damage
   ↓
11. Tesla API unlocks vehicle
   ↓
12. Tour starts on tablet app
   ↓
13. GPS triggers audio narration
   ↓
14. Tour data logged to database
   ↓
15. Check-out via voice or app
   ↓
16. Revenue split calculated
   ↓
17. Partner statement generated
```

---

## 💻 Technology Stack

### Backend Services
- **Runtime**: Node.js 20 + TypeScript
- **Framework**: Express.js
- **Databases**: PostgreSQL 16, Redis 7, Qdrant
- **Message Queue**: RabbitMQ
- **API Gateway**: Kong
- **Automation**: n8n

### Frontend
- **Customer Portal**: WordPress + WooCommerce + Amelia
- **Admin Dashboards**: Retool (MVP) → React (Production)
- **Mobile App**: React Native + Expo

### Infrastructure
- **Cloud Provider**: AWS (EKS, RDS, ElastiCache, S3)
- **Containers**: Docker + Kubernetes
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana

### Third-Party Integrations
- **Tesla API**: Vehicle control, telemetry, location tracking
- **Vapi**: AI voice agent for check-in/out
- **VoiceMap**: GPS tour engine and content delivery
- **Twilio**: SMS/MMS communication
- **Stripe**: Payment processing
- **Google Maps API**: Routing and visualization
- **AWS Rekognition**: Damage detection from photos
- **Mixpanel**: Product analytics

---

## 🚀 Quick Start

### Prerequisites

- **Node.js** 20+
- **Docker** & Docker Compose
- **PostgreSQL** 16+
- **Redis** 7+
- **AWS Account** (for S3, RDS)
- **API Keys**:
  - Tesla API token
  - Vapi account
  - Twilio credentials
  - Stripe API keys
  - Google Maps API key

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/TAVX.git
cd TAVX
```

### 2. Set Up Environment

```bash
cp .env.example .env
# Edit .env with your API keys and configuration
```

### 3. Start Development Services

```bash
cd infrastructure/docker
docker-compose up -d
```

This starts:
- PostgreSQL database
- Redis cache
- RabbitMQ message queue
- Qdrant vector database

### 4. Initialize Database

```bash
npm run db:migrate
npm run db:seed
```

### 5. Start Backend Services

```bash
# Booking service
cd services/booking
npm install
npm run dev

# Vehicle service
cd ../vehicle
npm install
npm run dev

# Repeat for other services...
```

### 6. Start Frontend

```bash
# Mobile app
cd mobile-app
npm install
npm start

# WordPress (separate installation)
# Follow docs/guides/wordpress-setup.md
```

---

## 📊 Business Model

### Revenue Streams

1. **Rental Revenue**
   - Base rental: $400-450/week per vehicle
   - Dynamic pricing based on demand
   - Insurance add-ons

2. **Tour Packages**
   - 1-Hour Tour: $75
   - 2-Hour Tour: $125
   - 4-Hour Tour: $225
   - Full-Day Custom: $450

3. **Partner Revenue Share**
   - Tier 1 (1-3 vehicles): 50/50 split
   - Tier 2 (4-12 vehicles): 55/45 split (partner favor)
   - Tier 3 (13+ vehicles): 60/40 split (partner favor)

### Target Metrics

| Metric | Year 1 Target |
|--------|---------------|
| **Fleet Size** | 100 vehicles |
| **Utilization Rate** | 85%+ |
| **Average Booking Value** | $500+ |
| **Tour Adoption Rate** | 60%+ |
| **Customer Satisfaction** | 4.5+ stars |
| **Revenue per Vehicle** | $40K+ annually |
| **Monthly Bookings** | 1,000+ |

---

## 🎯 Use Cases

### Tourist Experience
*"Sarah from Seattle"*
- Books Tesla Model Y + Oakland Heritage Tour online
- Receives SMS with pickup details
- Calls AI agent for 5-minute voice check-in
- Drives to Jack London Square, tour automatically starts
- Learns Oakland's history while exploring the city
- Returns vehicle via voice check-out
- Receives discount code for next visit

### Fleet Partner
*"James - owns 5 Teslas"*
- Invests in 5 Tesla vehicles
- Lets TAV-X manage bookings, maintenance, operations
- Logs into partner portal to see real-time earnings
- Receives automated monthly statements
- Earns $200K+ annually with minimal effort
- Uses ROI calculator to plan fleet expansion

### Operations Team
*"Maria - Fleet Manager"*
- Monitors 100 vehicles on real-time dashboard
- Receives Slack alert for low-battery vehicle
- Assigns VA to charge vehicle at supercharger
- Processes damage report with AI-flagged photos
- Reviews daily revenue and booking pipeline
- Generates partner payout reports at month-end

---

## 📈 Roadmap

### Phase 1: MVP (Months 1-3)
- [x] Complete PRD and technical architecture
- [ ] Build booking system (WordPress + Airtable)
- [ ] Implement voice check-in (Vapi)
- [ ] Deploy 1 tour route (Oakland Heritage)
- [ ] Onboard 10 pilot vehicles
- [ ] Launch to friends & family

### Phase 2: Scale (Months 4-6)
- [ ] Add 2 more tour routes
- [ ] Scale to 30 vehicles
- [ ] Launch partner portal
- [ ] Hire 2 Philippines VAs
- [ ] Implement advanced analytics
- [ ] Public marketing campaign

### Phase 3: Enterprise (Months 7-12)
- [ ] Expand to 100 vehicles
- [ ] Partner with 10+ hotels
- [ ] Integrate with OTAs (Expedia, Viator)
- [ ] Build customer mobile app
- [ ] Expand to San Francisco market
- [ ] Create franchise playbook

### Phase 4: National Expansion (Year 2)
- [ ] Launch in 5 additional cities
- [ ] White-label solutions for partners
- [ ] Advanced AI conversational tours
- [ ] API for third-party integrations
- [ ] National brand partnerships

---

## 📚 Documentation

### Essential Reading

1. **[Product Requirements Document](docs/prd/Initial_PRD.md)** - Complete business and feature requirements
2. **[Architecture Specification Part 1](docs/architecture/Architecture_Specification_Part1.md)** - Foundation, database, APIs
3. **[Architecture Specification Part 2](docs/architecture/Architecture_Specification_Part2.md)** - Deployment, testing, monitoring
4. **[Architecture Specification Part 3](docs/architecture/Architecture_Specification_Part3.md)** - Tour engine, mobile app
5. **[Implementation Summary](docs/Implementation_Summary.md)** - Quick reference for Claude Code

### API Documentation
- REST API endpoints (coming soon)
- WebSocket real-time updates (coming soon)
- Webhook integrations (coming soon)

---

## 🔒 Security & Compliance

### Data Protection
- ✅ End-to-end encryption for sensitive data
- ✅ PII handling compliant with GDPR/CCPA
- ✅ Secure API key management (AWS Secrets Manager)
- ✅ Role-based access control (RBAC)
- ✅ Rate limiting on all public endpoints

### Payment Security
- ✅ PCI DSS compliant (via Stripe)
- ✅ No credit card storage on our servers
- ✅ Tokenized payment processing
- ✅ Fraud detection and prevention

### Vehicle Security
- ✅ Digital key encryption
- ✅ Time-limited vehicle access
- ✅ GPS tracking and geofencing
- ✅ Emergency kill-switch capability

---

## 🧪 Testing Strategy

### Unit Tests
```bash
npm run test:unit
```
- Service logic testing
- Utility function testing
- 80%+ code coverage target

### Integration Tests
```bash
npm run test:integration
```
- API endpoint testing
- Database interaction testing
- External API mocking

### End-to-End Tests
```bash
npm run test:e2e
```
- Full user journey testing
- Cypress for web flows
- Detox for mobile app flows

### Load Testing
```bash
npm run test:load
```
- k6 for API load testing
- Target: 1000 concurrent users
- P95 latency < 200ms

---

## 🤝 Contributing

This is a proprietary project for Tesla EV Rentals Inc / TAV-X operations. For collaboration inquiries, please contact the project owner.

---

## 📞 Support & Contact

**TAV-X - Tesla Autonomous Vehicle Experience**

- **Website**: [tavx.com](https://tavx.com) *(coming soon)*
- **Email**: support@tavx.com
- **GitHub**: This repository
- **Location**: Oakland, California

---

## 📄 License

Proprietary - All Rights Reserved © 2025 Tesla EV Rentals Inc / TAV-X

---

## 🙏 Acknowledgments

- **Oakland Museum of California** - Historical content collaboration
- **Black Panther Party Legacy Project** - Cultural consulting
- **VoiceMap** - GPS tour platform
- **Vapi** - AI voice technology
- **Tesla** - Vehicle API and innovation

---

## ✅ Development Checklist

**For Claude Code / Developers:**

- [ ] Review complete PRD
- [ ] Study all 3 architecture specification documents
- [ ] Set up local development environment
- [ ] Create Airtable base or PostgreSQL database
- [ ] Register for external API accounts (Tesla, Vapi, Twilio, Stripe)
- [ ] Implement authentication service
- [ ] Build booking service with Airtable/WordPress
- [ ] Integrate Tesla API for vehicle control
- [ ] Set up Vapi voice agents
- [ ] Build mobile app for in-vehicle tours
- [ ] Deploy to staging environment
- [ ] Conduct user acceptance testing
- [ ] Launch MVP to pilot users

---

**Ready to revolutionize Tesla rentals?** Start with the [Implementation Summary](docs/Implementation_Summary.md) 🚀

---

**Status**: In Development | **Version**: 1.0.0-alpha | **Last Updated**: November 18, 2025
