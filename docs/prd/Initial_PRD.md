# Product Requirements Document (PRD)
## TAV-X Autonomous Tour & Rental Operating System

**Version:** 1.0  
**Date:** November 18, 2025  
**Owner:** Tesla EV Rentals Inc / TAV-X  
**Status:** Draft for Development

---

## 1. Executive Summary

### 1.1 Product Vision
Build a comprehensive, AI-powered operating system that manages the entire lifecycle of Tesla rentals and guided tours in Oakland—from voice-guided vehicle check-in to GPS-enabled historical tours, real-time fleet tracking, and automated revenue reconciliation.

### 1.2 Success Metrics
- **Operational Efficiency:** Reduce check-in time from 30 minutes to 5 minutes
- **Tour Adoption:** 60% of renters opt for guided tour experiences
- **Fleet Utilization:** 85%+ vehicle utilization rate
- **Customer Satisfaction:** 4.5+ star average rating
- **Revenue Growth:** $40K+ per vehicle annually

### 1.3 Target Users
1. **Customers:** Tourists and locals seeking Tesla rental + guided tour experiences
2. **Fleet Operators:** TAV-X staff managing vehicle check-in/out and maintenance
3. **Fleet Partners:** Individual investors who own vehicles in the network
4. **System Administrators:** Platform managers overseeing operations

---

## 2. Product Overview

### 2.1 Core System Components

```
┌─────────────────────────────────────────────────────────┐
│              TAV-X Operating System                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Customer   │  │   Vehicle    │  │    Fleet     │ │
│  │   Booking    │  │   Check-In   │  │  Management  │ │
│  │   Portal     │  │   System     │  │   Dashboard  │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  AI Voice    │  │  GPS Tour    │  │   History    │ │
│  │   Guide      │  │   Engine     │  │  Tracking    │ │
│  │  (Vapi)      │  │ (VoiceMap)   │  │  Database    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Payment    │  │  Analytics   │  │   Partner    │ │
│  │   Engine     │  │   & Reports  │  │   Portal     │ │
│  │  (Stripe)    │  │  (Metabase)  │  │             │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Feature Requirements

### 3.1 Customer Booking Portal

#### 3.1.1 Booking Interface
**User Story:** As a customer, I want to easily browse available Teslas and tour options so I can book my experience quickly.

**Requirements:**
- **Homepage:**
  - Real-time vehicle availability calendar
  - Filter by: Model (3/Y), FSD capability, price range, pickup location
  - Dynamic pricing based on demand and duration
  
- **Booking Flow:**
  1. Select dates and vehicle type
  2. Choose tour package (or rental-only)
  3. Add driver information and insurance
  4. Payment processing
  5. Instant confirmation via email/SMS

- **Tour Packages:**
  - **Option 1:** Rental Only ($400-450/week)
  - **Option 2:** 1-Hour Historical Tour ($75)
  - **Option 3:** 2-Hour Bay Area Tour ($125)
  - **Option 4:** 4-Hour Wine Country Tour ($225)
  - **Option 5:** Full-Day Custom Tour ($450)

**Technical Requirements:**
- WordPress + WooCommerce + Amelia Booking plugin
- Mobile-responsive design
- Integration with Stripe for payments
- Automated confirmation emails via n8n

---

### 3.2 Voice-Guided Check-In System

#### 3.2.1 AI Voice Agent (Vapi Integration)
**User Story:** As a customer arriving for pickup, I want to complete check-in via voice conversation without waiting for staff.

**Requirements:**

**Pre-Arrival:**
- Customer receives SMS 30 minutes before pickup with:
  - Parking lot location (500 Grand Parking, Oakland)
  - Vehicle spot number
  - Check-in phone number

**Voice Check-In Flow:**
1. **Customer calls check-in number**
2. **AI Agent (Vapi) greets customer:**
   - "Welcome to Tesla EV Rentals! Please provide your confirmation number."
3. **Verification:**
   - Confirms booking details
   - Verifies driver's license (via SMS photo upload)
   - Reviews rental agreement terms
4. **Vehicle Walkthrough:**
   - Guided inspection via voice prompts:
     - "Please walk around the vehicle and confirm no visible damage"
     - "Check front bumper, sides, rear, wheels"
     - "Take 4 photos and text them to this number"
5. **Interior Setup:**
   - "Locate the tablet mounted on the dashboard"
   - "Your tour guide is pre-loaded and ready"
   - "Ensure phone is connected via Bluetooth"
6. **Final Instructions:**
   - Charging locations and instructions
   - Emergency contact information
   - Tour start command: "Say 'Start Tour' when ready"
7. **Door Unlock:**
   - Tesla API triggered to unlock vehicle
   - Customer receives digital key on Tesla app

**Technical Requirements:**
- **Vapi Voice Agent:**
  - Custom trained model with TAV-X scripts
  - Integration with Airtable (booking database)
  - SMS gateway via Twilio
  - Tesla API for vehicle control
  
- **Conversation Context Storage:**
  - Store full conversation in Qdrant vector database
  - Flag any issues (damage reports, concerns)
  - Auto-notify operations team via Slack

- **Photo Upload & Inspection:**
  - MMS handling via Twilio
  - Computer vision (AWS Rekognition or Google Vision API) for damage detection
  - Store images in S3 with metadata linking to booking ID

---

### 3.3 GPS Tour Engine with Historical Content

#### 3.3.1 Oakland Historical Tours
**User Story:** As a tourist, I want the vehicle to guide me through Oakland's history with location-triggered audio narration.

**Tour Categories:**

**1. Oakland Heritage Tour (1 hour)**
- Jack London Square
- Oakland Museum of California
- Preservation Park Victorian homes
- Historic Paramount Theatre
- Old Oakland district

**2. Black Panther Party Historical Tour (2 hours)**
- Black Panther Party founding locations
- Bobby Hutton Memorial Park
- Defermery Park
- West Oakland BART murals
- Community programs legacy sites

**3. Bay Area Scenic Tour (4 hours)**
- Lake Merritt loop
- Oakland Hills viewpoints (Grizzly Peak)
- Redwood Regional Park
- Berkeley Marina
- Bay Bridge views from Treasure Island

**4. Full-Day Custom Experience (8 hours)**
- Combine multiple tours
- Add wine country (Napa/Sonoma)
- Customer-selected waypoints

#### 3.3.2 Tour Delivery System

**In-Vehicle Components:**
- **Mounted Tablet (iPad or Android):**
  - Tour interface with map overlay
  - Pre-downloaded VoiceMap content
  - Offline mode capability
  
- **Audio System Integration:**
  - Bluetooth connection to Tesla audio
  - Volume auto-adjustment
  - Pause/resume functionality

**Content Delivery Architecture:**

```
┌─────────────────────────────────────────────────┐
│           Tour Content Management               │
├─────────────────────────────────────────────────┤
│                                                 │
│  [Airtable: Tour Scripts Database]             │
│         ↓                                       │
│  [Content Management System]                    │
│    - Historical narratives                      │
│    - GPS waypoints                              │
│    - Audio files                                │
│         ↓                                       │
│  [VoiceMap Integration]                         │
│    - Route engine                               │
│    - Location triggers                          │
│    - Audio playback                             │
│         ↓                                       │
│  [In-Vehicle Tablet App]                        │
│    - Real-time GPS tracking                     │
│    - Progress indicator                         │
│    - Emergency assistance button                │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Technical Requirements:**

- **VoiceMap Platform:**
  - Create custom tours with GPS-triggered audio
  - Upload professional narration (voice actors or AI-generated)
  - Set geofence triggers (50-100m radius per point)
  
- **Tablet Application:**
  - React Native or Flutter for cross-platform
  - Offline map storage (MapBox or Google Maps offline)
  - Background location tracking
  - Analytics tracking (completed waypoints, skip rate)

- **Content Production:**
  - Partner with Oakland historians/cultural organizations
  - Record 15-20 minute narration per tour
  - Include music/ambient sound (royalty-free)
  - Multiple language support (English, Spanish, Mandarin priority)

---

### 3.4 History Tracking & Analytics System

#### 3.4.1 Comprehensive Data Tracking
**User Story:** As a fleet operator, I need complete visibility into every rental, tour, and vehicle interaction to optimize operations.

**Data Collection Points:**

**1. Booking History**
- Customer information
- Rental duration and dates
- Selected tour packages
- Payment amount and method
- Promo codes used
- Booking source (direct, partner, referral)

**2. Vehicle History**
- Check-in/check-out timestamps
- Pre-rental inspection photos
- Post-rental inspection photos
- Mileage at pickup and return
- Battery level at pickup and return
- Charging sessions during rental
- Damage reports (if any)

**3. Tour History**
- Tours started vs. completed
- Waypoints visited
- Average time per waypoint
- Skip rate per location
- Customer feedback per tour
- GPS breadcrumb trail

**4. Maintenance History**
- Cleaning logs
- Tire rotations and replacements
- Service appointments
- Software updates
- Repair costs and vendors

**5. Revenue History**
- Rental revenue per vehicle
- Tour package revenue
- Add-on services (insurance, GPS)
- Revenue split calculations (partner vs. TAV-X)
- Monthly, quarterly, annual reports

#### 3.4.2 Database Schema (Airtable)

**Core Tables:**

**1. Vehicles**
```
- Vehicle ID (primary key)
- VIN
- Model (3/Y)
- Year
- Color
- FSD Enabled (Y/N)
- Owner Partner ID (foreign key)
- Current Status (Available/Rented/Maintenance)
- Home Location
- Total Lifetime Revenue
- Total Miles Driven
- Acquisition Date
```

**2. Bookings**
```
- Booking ID (primary key)
- Customer ID (foreign key)
- Vehicle ID (foreign key)
- Pickup Date/Time
- Return Date/Time
- Tour Package Selected
- Total Price
- Payment Status
- Confirmation Code
- Booking Source
- Special Requests
```

**3. Customers**
```
- Customer ID (primary key)
- Name
- Email
- Phone
- Driver's License Number
- Address
- Total Bookings
- Lifetime Value
- Referral Source
```

**4. Tours**
```
- Tour ID (primary key)
- Tour Name
- Duration
- Route Waypoints (linked records)
- Narration Script Link
- Price
- Active Status
```

**5. Waypoints**
```
- Waypoint ID (primary key)
- Tour ID (foreign key)
- Location Name
- GPS Coordinates (lat/long)
- Historical Content
- Narration Audio URL
- Geofence Radius
- Average Visit Duration
```

**6. Check-In/Out Logs**
```
- Log ID (primary key)
- Booking ID (foreign key)
- Vehicle ID (foreign key)
- Timestamp
- Type (Check-In/Check-Out)
- Mileage
- Battery Level
- Photos (array of URLs)
- Inspector Name (or "AI Voice Agent")
- Damage Notes
```

**7. Tour Sessions**
```
- Session ID (primary key)
- Booking ID (foreign key)
- Tour ID (foreign key)
- Start Time
- End Time
- Waypoints Visited (array)
- Completion Rate
- GPS Trace (JSON)
- Customer Rating
```

**8. Partners**
```
- Partner ID (primary key)
- Name
- Entity Type (LLC/Individual)
- EIN
- Vehicles Owned (linked records)
- Revenue Split %
- Total Earnings
- Payment Method
- Contract Start Date
```

---

### 3.5 Fleet Management Dashboard

#### 3.5.1 Operations Command Center
**User Story:** As a fleet manager, I need a real-time dashboard to monitor all vehicles, bookings, and operations.

**Dashboard Views:**

**1. Fleet Status Overview**
- Map view showing all vehicle locations
- Status indicators:
  - 🟢 Available
  - 🔵 On Rental
  - 🟡 In Maintenance
  - 🔴 Issue Reported
- Battery levels for each vehicle
- Upcoming bookings in next 24 hours

**2. Active Rentals**
- List of currently rented vehicles
- Customer name and contact
- Expected return time
- Current location (if tour in progress)
- Tour completion status

**3. Maintenance Queue**
- Vehicles needing:
  - Cleaning
  - Charging
  - Inspection
  - Repair
- Assigned VA or staff member
- Estimated completion time

**4. Revenue Dashboard**
- Today's revenue
- Week/month/year comparisons
- Revenue by vehicle
- Revenue by tour package
- Partner payout calculations

**5. Alerts & Notifications**
- Overdue returns
- Low battery vehicles
- Damage reports
- Customer service requests
- Maintenance due

**Technical Requirements:**
- Built on Retool or custom React dashboard
- Real-time data sync from Airtable
- Tesla API integration for live vehicle data
- Slack integration for team notifications
- Mobile-responsive for field operations

---

### 3.6 Partner Portal

#### 3.6.1 Investor Dashboard
**User Story:** As a fleet partner, I want to see the performance of my vehicles and track my earnings.

**Features:**

**1. Portfolio Overview**
- Number of vehicles owned
- Total lifetime earnings
- Current month earnings
- Projected annual return

**2. Vehicle Performance**
- Revenue per vehicle
- Utilization rate (days rented / days available)
- Customer ratings per vehicle
- Maintenance costs

**3. Monthly Statements**
- Detailed earnings breakdown
- TAV-X service fees
- Net payout amount
- Payment status

**4. Growth Tools**
- Calculator: ROI for adding vehicles
- Financing options
- Vehicle acquisition support
- Expansion roadmap (1 → 5 → 12 → 50 vehicles)

**Technical Requirements:**
- Secure login portal (WordPress + member plugin)
- Automated PDF statement generation (n8n + Airtable)
- ACH/wire payment integration
- Mobile app (optional Phase 2)

---

## 4. Technical Architecture

### 4.1 System Stack

**Frontend:**
- **Customer Portal:** WordPress + WooCommerce + Amelia
- **Dashboards:** Retool or React + Tailwind CSS
- **Mobile App (Tour Tablet):** React Native or Flutter

**Backend:**
- **Database:** Airtable (primary source of truth)
- **Automation:** n8n (workflow orchestration)
- **CRM:** Vtiger (customer relationship management)
- **Voice AI:** Vapi (check-in agent)
- **Vector DB:** Qdrant (conversation history, tour content)

**Third-Party Integrations:**
- **Tesla API:** Vehicle control, telemetry, location
- **VoiceMap:** GPS tour engine
- **Twilio:** SMS/MMS for customer communication
- **Stripe:** Payment processing
- **AWS S3:** Photo and media storage
- **Google Maps API:** Route planning and display
- **Slack:** Internal team notifications

**Analytics:**
- **Metabase:** Business intelligence and reporting
- **Google Analytics:** Website tracking
- **Mixpanel:** Product analytics (tablet app usage)

### 4.2 Data Flow Architecture

```
Customer Booking
       ↓
WordPress (Booking Form)
       ↓
Airtable (Record Created)
       ↓
n8n Trigger
   ↓           ↓
Stripe      Twilio SMS
Payment     Confirmation
   ↓           ↓
Update      Customer
Airtable    Receives Details
       ↓
Check-In Day
       ↓
Customer Calls Vapi
       ↓
Voice Agent Confirms
       ↓
Tesla API Unlocks Vehicle
       ↓
Tour Started (Tablet App)
       ↓
GPS Tracking + Audio Playback
       ↓
Tour Data Logged to Airtable
       ↓
Check-Out Process
       ↓
Photos + Inspection Via SMS
       ↓
Vehicle Status Updated
       ↓
Revenue Split Calculated
       ↓
Partner Statement Generated
```

---

## 5. User Flows

### 5.1 Customer Journey: Booking to Return

**Phase 1: Discovery & Booking (Web)**
1. Customer lands on tavx.com
2. Browses available Teslas and tours
3. Selects dates, vehicle, tour package
4. Completes payment
5. Receives confirmation email + SMS

**Phase 2: Pre-Arrival (24 hours before)**
6. Receives reminder SMS with:
   - Pickup location details
   - Check-in phone number
   - What to bring (license, insurance)

**Phase 3: Check-In (On-Site)**
7. Arrives at 500 Grand Parking
8. Calls check-in number
9. AI voice agent guides through:
   - Identity verification
   - Vehicle inspection
   - Photo documentation
   - Safety instructions
10. Receives digital key via Tesla app
11. Vehicle unlocked remotely

**Phase 4: Tour Experience (In-Vehicle)**
12. Opens tablet app in vehicle
13. Selects tour or custom route
14. Starts tour (audio begins automatically)
15. Follows GPS route with historical narration
16. Can pause, skip, or replay segments
17. Emergency support button available

**Phase 5: Check-Out (Return)**
18. Returns vehicle to designated spot
19. Calls check-out number or uses app
20. AI agent guides final inspection
21. Submits final photos via SMS
22. Confirms mileage and battery level
23. Receives receipt and requests feedback

**Phase 6: Post-Rental**
24. Email survey for feedback
25. Tour highlights video sent (optional)
26. Discount code for next booking
27. Invitation to leave review

---

### 5.2 Fleet Operator Flow: Daily Operations

**Morning Routine:**
1. Log into dashboard
2. Review overnight bookings
3. Check vehicle status (battery, location)
4. Assign cleaning/maintenance tasks to VAs
5. Confirm check-ins scheduled for today

**During Day:**
6. Monitor active rentals on map
7. Respond to customer support requests via Slack
8. Handle check-in/check-out exceptions
9. Process damage reports
10. Coordinate charging for low-battery vehicles

**Evening Review:**
11. Review day's revenue
12. Update maintenance logs
13. Plan next day's logistics
14. Generate partner payout reports (monthly)

---

## 6. Oakland Historical Tour Content Requirements

### 6.1 Content Strategy

**Primary Goals:**
- Educate visitors about Oakland's rich cultural history
- Highlight diverse communities and social movements
- Promote local businesses and attractions
- Provide entertaining, accurate narratives

**Content Sources:**
- Oakland Museum of California archives
- Local historians and cultural consultants
- Black Panther Party Legacy Project
- Jack London Square Foundation
- Oakland Public Library historical collections

### 6.2 Tour Script Development

**Tour 1: Oakland Heritage Tour (1 Hour)**

**Waypoint 1: Jack London Square**
- **Duration:** 8 minutes
- **Content:**
  - History of Jack London (author, adventurer)
  - Waterfront development and maritime history
  - Heinold's First and Last Chance Saloon
  - Modern attractions and restaurants
- **Narration Sample:**
  > "Welcome to Jack London Square, named after Oakland's most famous literary son. Jack London, author of *The Call of the Wild* and *White Fang*, spent his youth along these very waterfront docks..."

**Waypoint 2: Old Oakland**
- **Duration:** 6 minutes
- **Content:**
  - Victorian-era architecture
  - 1906 earthquake impact
  - Revival as restaurant and art district
  - Swan's Market and Friday farmers market

**Waypoint 3: Paramount Theatre**
- **Duration:** 7 minutes
- **Content:**
  - Art Deco masterpiece (1931)
  - Oakland Symphony and ballet performances
  - Historic preservation efforts
  - Tips for attending shows

**Waypoint 4: Lake Merritt**
- **Duration:** 10 minutes
- **Content:**
  - First wildlife refuge in North America (1870)
  - Kaiser Roof Garden
  - Cultural festivals and events
  - Recreational activities

**Tour 2: Black Panther Party Historical Tour (2 Hours)**

**Waypoint 1: 5624 Martin Luther King Jr. Way (BPP Founding Site)**
- **Duration:** 12 minutes
- **Content:**
  - October 1966 founding by Huey Newton and Bobby Seale
  - 10-Point Program origins
  - Community survival programs
  - Historical context of Oakland in the 1960s

**Waypoint 2: Defermery Park**
- **Duration:** 10 minutes
- **Content:**
  - Community gathering site
  - Free Breakfast for Children Program launch
  - Youth programs and activities
  - Modern community center

**Waypoint 3: Bobby Hutton Memorial Park**
- **Duration:** 12 minutes
- **Content:**
  - Bobby Hutton's story (first BPP recruit, killed 1968)
  - April 6, 1968 shootout with Oakland Police
  - Legacy of youth activism
  - Park dedication and community impact

**Waypoint 4: West Oakland BART Station Murals**
- **Duration:** 8 minutes
- **Content:**
  - Public art celebrating BPP legacy
  - Artist collaboration and community input
  - Symbols and imagery explained
  - Ongoing community organizing

[Additional waypoints for full 2-hour tour...]

### 6.3 Content Production Standards

**Audio Quality:**
- Professional recording studio
- Voice talent with appropriate tone (authoritative, warm)
- Background music (subtle, period-appropriate)
- Sound effects for immersion

**Accuracy:**
- Fact-checking by historians
- Cultural sensitivity review
- Citations for historical claims
- Regular content updates

**Accessibility:**
- Closed captions on tablet display
- Multiple language versions
- Adjustable playback speed
- Text summaries available

---

## 7. Implementation Phases

### Phase 1: MVP Launch (Months 1-3)

**Goals:**
- Launch basic rental booking system
- Implement voice-guided check-in
- Deploy 1 pilot tour (Oakland Heritage)
- Onboard 10 vehicles

**Deliverables:**
- WordPress booking site live
- Airtable database configured
- Vapi voice agent trained and tested
- VoiceMap tour published
- 10 tablets equipped in vehicles
- Operations dashboard (basic)

**Success Metrics:**
- 50+ bookings in Month 3
- 90%+ check-in completion via voice
- 4.0+ star customer rating
- 70%+ vehicle utilization

---

### Phase 2: Scale Operations (Months 4-6)

**Goals:**
- Add 2 more tours (BPP History, Bay Area Scenic)
- Scale fleet to 30 vehicles
- Launch partner portal
- Hire 2 Philippines VAs for operations

**Deliverables:**
- 3 total tours live
- Partner dashboard with automated statements
- VA team trained on operations
- Enhanced analytics in Metabase
- Customer referral program

**Success Metrics:**
- 200+ bookings per month
- 80%+ tour adoption rate
- 30 vehicles generating $40K+ annually
- 5 new fleet partners onboarded

---

### Phase 3: Enterprise Expansion (Months 7-12)

**Goals:**
- Launch full-day custom tours
- Partner with hotels and travel agencies
- Expand to 100 vehicles
- Develop mobile app for customers

**Deliverables:**
- Hotel concierge partnerships (10+ hotels)
- Integration with Expedia, Viator
- Mobile app (iOS + Android)
- Advanced AI tour guide features (conversational)
- Franchise playbook for new cities

**Success Metrics:**
- 1,000+ bookings per month
- $4M+ annual revenue
- 100 vehicles in Oakland
- 15+ fleet partners
- Prepare for expansion to SF, San Jose

---

## 8. Risk Management

### 8.1 Operational Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Vehicle damage during rental | High | Comprehensive insurance, deposit requirements, damage waiver options |
| Customer accidents | High | Thorough safety briefing, FSD supervision requirements, 24/7 support |
| Battery range anxiety | Medium | Pre-rental charging checklist, charging station map in app, supercharger credit |
| Check-in technology failure | Medium | Backup manual process, on-call staff for troubleshooting |
| Tour content inaccuracy | Low | Expert review process, regular updates, customer feedback loop |

### 8.2 Technical Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Airtable API limits | Medium | Implement caching, consider migration to PostgreSQL at scale |
| Tesla API changes | High | Monitor Tesla developer forums, maintain backup manual processes |
| Voice AI misunderstandings | Medium | Extensive testing, fallback to human agent, continuous training |
| GPS/cellular dead zones | Low | Offline mode for tours, pre-downloaded content |

### 8.3 Business Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Low demand for tours | High | Market research, pilot testing, flexible pricing, marketing campaigns |
| Partner disputes over revenue | Medium | Clear contracts, transparent reporting, regular communication |
| Regulatory changes (SF/Oakland) | Medium | Legal counsel, industry association membership, adaptive compliance |
| Competition from traditional rentals | Low | Differentiation through AI tours, superior service, FSD experience |

---

## 9. Success Metrics & KPIs

### 9.1 Operational Metrics
- **Vehicle Utilization Rate:** Target 85%+
- **Average Rental Duration:** Target 4+ days
- **Check-In Time:** Target <5 minutes
- **Check-Out Time:** Target <5 minutes
- **Vehicle Downtime:** Target <10%

### 9.2 Customer Metrics
- **Customer Satisfaction (CSAT):** Target 4.5+ / 5.0
- **Net Promoter Score (NPS):** Target 50+
- **Tour Completion Rate:** Target 90%+
- **Repeat Booking Rate:** Target 30%+
- **Referral Rate:** Target 20%+

### 9.3 Financial Metrics
- **Revenue per Vehicle:** Target $40K+ annually
- **Average Booking Value:** Target $500+
- **Tour Upgrade Rate:** Target 60%+
- **Customer Acquisition Cost (CAC):** Target <$50
- **Lifetime Value (LTV):** Target $1,500+

### 9.4 Growth Metrics
- **Monthly Booking Growth:** Target 20%+ MoM
- **Fleet Growth:** 10 → 30 → 100 vehicles (Year 1)
- **Partner Onboarding:** Target 15+ partners Year 1
- **Market Share in Oakland:** Target 25% of premium EV rentals

---

## 10. Budget & Resource Requirements

### 10.1 Technology Stack Costs (Annual)

| Item | Provider | Annual Cost |
|------|----------|-------------|
| Airtable Pro | Airtable | $2,400 |
| n8n Cloud | n8n | $2,400 |
| Vapi Voice AI | Vapi | $6,000 |
| Qdrant Cloud | Qdrant | $1,200 |
| WordPress Hosting | WP Engine | $3,600 |
| Twilio SMS/Voice | Twilio | $4,800 |
| VoiceMap Platform | VoiceMap | $1,200 |
| Tesla API Access | Tesla | $0 (free) |
| AWS S3 Storage | Amazon | $1,200 |
| Stripe Processing | Stripe | 2.9% + $0.30/txn |
| Google Maps API | Google | $2,400 |
| Retool Dashboards | Retool | $1,200 |
| **Total** | | **~$27K/year** |

### 10.2 Staffing Requirements

**Year 1:**
- **Founder/CEO (Don):** Operations, partnerships, strategy
- **Philippines VAs (2):** Customer service, fleet logistics, cleaning coordination
- **Part-Time Developer (Contractor):** System integration, maintenance
- **Content Producer (Contractor):** Tour script writing, audio production

**Year 2:**
- Add: Fleet Operations Manager, Sales/Partnerships Lead, 2 additional VAs

### 10.3 Marketing Budget

**Year 1:** $75K
- Digital ads: $30K (Google, Meta, Yelp)
- Content creation: $15K (video, photography)
- Partnerships/commissions: $20K
- Events/trade shows: $10K

---

## 11. Appendices

### Appendix A: Voice Agent Script Template

```
[CUSTOMER CALLS CHECK-IN NUMBER]

AI: "Hello! Welcome to Tesla EV Rentals. This is your AI check-in assistant. 
     May I have your confirmation number?"

CUSTOMER: [Provides number]

AI: "Perfect! I have your reservation. You're picking up a Tesla Model Y 
     for 7 days with the Oakland Heritage Tour package. Is that correct?"

CUSTOMER: "Yes."

AI: "Great! Let's get you on the road. First, I'll need to verify your 
     driver's license. Can you text a clear photo of the front of your 
     license to this number: (510) 555-0199?"

[CUSTOMER SENDS PHOTO]

AI: "Photo received. Thank you, [Name]. Now, please walk to the vehicle. 
     It's parked in spot B-12. Let me know when you're there."

CUSTOMER: "I'm here."

AI: "Perfect. Let's do a quick vehicle inspection. Please walk around 
     the car slowly and check for any scratches, dents, or damage. 
     Take one photo of each side—front, driver side, rear, passenger side. 
     Text all four photos to the same number."

[CUSTOMER SENDS PHOTOS]

AI: "Photos received. I don't see any new damage. The vehicle looks good 
     to go. Now, here's what you need to know..."

[Continue with safety briefing, tour instructions, emergency contacts...]

AI: "All set! I'm unlocking the vehicle now. The doors will open in 
     5 seconds. Enjoy your Oakland adventure!"

[TESLA API TRIGGERS UNLOCK]
```

### Appendix B: Tour Waypoint Data Model

```json
{
  "tour_id": "OAK-HERITAGE-001",
  "tour_name": "Oakland Heritage Tour",
  "duration_minutes": 60,
  "waypoints": [
    {
      "waypoint_id": "WP-001",
      "name": "Jack London Square",
      "latitude": 37.7956,
      "longitude": -122.2778,
      "geofence_radius_meters": 100,
      "audio_file_url": "https://s3.../jack-london-square.mp3",
      "narration_duration_seconds": 480,
      "transcript": "Welcome to Jack London Square...",
      "historical_facts": [
        "Named after author Jack London",
        "Waterfront redevelopment began 1980s",
        "Heinold's First and Last Chance built 1883"
      ],
      "images": [
        "https://s3.../jack-london-1.jpg",
        "https://s3.../jack-london-2.jpg"
      ]
    }
  ]
}
```

### Appendix C: Partner Revenue Split Calculator

```
TIER 1 (Entry Level):
- Vehicle Count: 1-3
- Revenue Split: 50/50
- Services: Basic fleet management, bookings, maintenance coordination

Example:
- Vehicle Revenue: $40,000/year
- Partner Earnings: $20,000/year
- TAV-X Earnings: $20,000/year

TIER 2 (Growth Level):
- Vehicle Count: 4-12
- Revenue Split: 55/45 (partner favor)
- Services: Priority scheduling, marketing support, dedicated VA

Example:
- 5 Vehicles × $40K = $200,000/year
- Partner Earnings: $110,000/year
- TAV-X Earnings: $90,000/year

TIER 3 (Enterprise Level):
- Vehicle Count: 13+
- Revenue Split: 60/40 (partner favor)
- Services: White-glove service, expansion consulting, financing assistance

Example:
- 20 Vehicles × $45K = $900,000/year
- Partner Earnings: $540,000/year
- TAV-X Earnings: $360,000/year
```

---

## 12. Next Steps & Action Items

### Immediate Actions (Week 1-2)
- [ ] Review and approve PRD with team
- [ ] Select technology vendors (finalize contracts)
- [ ] Hire part-time developer for integration work
- [ ] Begin Airtable database schema build
- [ ] Script first tour (Oakland Heritage)
- [ ] Record voice talent auditions

### Short-Term (Month 1)
- [ ] Complete WordPress booking site
- [ ] Configure Vapi voice agent
- [ ] Test end-to-end booking flow
- [ ] Produce first tour audio
- [ ] Equip 5 pilot vehicles with tablets
- [ ] Soft launch to friends & family

### Medium-Term (Months 2-3)
- [ ] Public launch with marketing campaign
- [ ] Onboard first 5 fleet partners
- [ ] Complete BPP Historical Tour
- [ ] Implement analytics dashboards
- [ ] Hire Philippines VA team

### Long-Term (Months 4-12)
- [ ] Scale to 100 vehicles
- [ ] Launch partner with 10+ hotels
- [ ] Expand to San Francisco market
- [ ] Develop mobile app
- [ ] Franchise playbook creation

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Nov 18, 2025 | TAV-X Product Team | Initial PRD creation |

**Approval**

- [ ] CEO/Founder (Don) - Strategy & Vision
- [ ] Operations Lead - Operational Feasibility
- [ ] Technical Lead - Technical Architecture
- [ ] Finance - Budget Approval

---

*This PRD is a living document and will be updated as requirements evolve and new insights emerge from customer feedback and operational experience.*