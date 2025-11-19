# TAV-X Architecture Specification - Part 3
## Tour Engine, Mobile Apps & Final Implementation Details

---

## 10. TOUR ENGINE COMPLETE IMPLEMENTATION

### 10.1 In-Vehicle Tablet Application

**App Structure (React Native + Expo)**

```typescript
// mobile-app/src/navigation/AppNavigator.tsx

import { createStackNavigator } from '@react-navigation/stack';
import { HomeScreen } from '../screens/HomeScreen';
import { TourSelectionScreen } from '../screens/TourSelectionScreen';
import { ActiveTourScreen } from '../screens/ActiveTourScreen';
import { WaypointDetailScreen } from '../screens/WaypointDetailScreen';
import { TourCompleteScreen } from '../screens/TourCompleteScreen';

const Stack = createStackNavigator();

export const AppNavigator = () => {
  return (
    <Stack.Navigator>
      <Stack.Screen 
        name="Home" 
        component={HomeScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen 
        name="TourSelection" 
        component={TourSelectionScreen}
        options={{ title: 'Choose Your Tour' }}
      />
      <Stack.Screen 
        name="ActiveTour" 
        component={ActiveTourScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen 
        name="WaypointDetail" 
        component={WaypointDetailScreen}
        options={{ presentation: 'modal' }}
      />
      <Stack.Screen 
        name="TourComplete" 
        component={TourCompleteScreen}
        options={{ headerShown: false }}
      />
    </Stack.Navigator>
  );
};
```

### 10.2 GPS Tour Tracking Service

```typescript
// mobile-app/src/services/TourTrackingService.ts

import * as Location from 'expo-location';
import { Audio } from 'expo-av';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface Waypoint {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  geofenceRadius: number;
  narrationAudioUrl: string;
  sequence: number;
}

interface TourSession {
  sessionId: string;
  tourId: string;
  bookingId: string;
  startTime: Date;
  currentWaypointIndex: number;
  waypointsVisited: string[];
  gpsTrace: Array<{lat: number; lng: number; timestamp: Date}>;
}

export class TourTrackingService {
  private locationSubscription: Location.LocationSubscription | null = null;
  private currentSound: Audio.Sound | null = null;
  private session: TourSession | null = null;
  private waypoints: Waypoint[] = [];

  async startTour(tourId: string, bookingId: string, waypoints: Waypoint[]) {
    this.waypoints = waypoints.sort((a, b) => a.sequence - b.sequence);
    
    // Create session
    this.session = {
      sessionId: `session-${Date.now()}`,
      tourId,
      bookingId,
      startTime: new Date(),
      currentWaypointIndex: 0,
      waypointsVisited: [],
      gpsTrace: []
    };

    // Save session to local storage (offline capability)
    await this.saveSession();

    // Request location permissions
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') {
      throw new Error('Location permission not granted');
    }

    // Start tracking
    this.locationSubscription = await Location.watchPositionAsync(
      {
        accuracy: Location.Accuracy.High,
        timeInterval: 5000, // Update every 5 seconds
        distanceInterval: 10 // Or every 10 meters
      },
      this.handleLocationUpdate.bind(this)
    );

    // Sync to API
    await this.syncSessionToAPI();
  }

  private async handleLocationUpdate(location: Location.LocationObject) {
    if (!this.session) return;

    const { latitude, longitude } = location.coords;

    // Add to GPS trace
    this.session.gpsTrace.push({
      lat: latitude,
      lng: longitude,
      timestamp: new Date()
    });

    // Check proximity to next waypoint
    const nextWaypoint = this.waypoints[this.session.currentWaypointIndex];
    if (nextWaypoint) {
      const distance = this.calculateDistance(
        latitude,
        longitude,
        nextWaypoint.latitude,
        nextWaypoint.longitude
      );

      // If within geofence, trigger audio
      if (distance <= nextWaypoint.geofenceRadius) {
        await this.triggerWaypoint(nextWaypoint);
      }
    }

    // Save session periodically
    await this.saveSession();

    // Sync to API every 30 seconds
    if (this.session.gpsTrace.length % 6 === 0) {
      await this.syncSessionToAPI();
    }
  }

  private async triggerWaypoint(waypoint: Waypoint) {
    if (!this.session) return;

    // Check if already visited
    if (this.session.waypointsVisited.includes(waypoint.id)) {
      return;
    }

    console.log(`Reached waypoint: ${waypoint.name}`);

    // Play audio narration
    await this.playAudio(waypoint.narrationAudioUrl);

    // Mark as visited
    this.session.waypointsVisited.push(waypoint.id);
    this.session.currentWaypointIndex++;

    // Log to API
    await this.logWaypointVisit(waypoint.id);

    // Save session
    await this.saveSession();
  }

  private async playAudio(audioUrl: string) {
    try {
      // Stop current audio if playing
      if (this.currentSound) {
        await this.currentSound.stopAsync();
        await this.currentSound.unloadAsync();
      }

      // Load and play new audio
      const { sound } = await Audio.Sound.createAsync(
        { uri: audioUrl },
        { shouldPlay: true }
      );

      this.currentSound = sound;

      // Cleanup when finished
      sound.setOnPlaybackStatusUpdate((status) => {
        if (status.isLoaded && status.didJustFinish) {
          sound.unloadAsync();
          this.currentSound = null;
        }
      });
    } catch (error) {
      console.error('Error playing audio:', error);
    }
  }

  private calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
  ): number {
    // Haversine formula
    const R = 6371e3; // Earth radius in meters
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  private async saveSession() {
    if (!this.session) return;
    
    await AsyncStorage.setItem(
      `tour_session_${this.session.sessionId}`,
      JSON.stringify(this.session)
    );
  }

  private async syncSessionToAPI() {
    if (!this.session) return;

    try {
      await fetch(`${process.env.API_URL}/tours/sessions/${this.session.sessionId}/sync`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(this.session)
      });
    } catch (error) {
      console.log('Failed to sync session, will retry later:', error);
      // Continue offline - will sync when connection restored
    }
  }

  private async logWaypointVisit(waypointId: string) {
    try {
      await fetch(`${process.env.API_URL}/tours/sessions/${this.session?.sessionId}/waypoint`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          waypointId,
          timestamp: new Date(),
          location: {
            latitude: this.session?.gpsTrace[this.session.gpsTrace.length - 1]?.lat,
            longitude: this.session?.gpsTrace[this.session.gpsTrace.length - 1]?.lng
          }
        })
      });
    } catch (error) {
      console.log('Failed to log waypoint visit:', error);
    }
  }

  async stopTour() {
    // Stop location tracking
    if (this.locationSubscription) {
      this.locationSubscription.remove();
      this.locationSubscription = null;
    }

    // Stop audio
    if (this.currentSound) {
      await this.currentSound.stopAsync();
      await this.currentSound.unloadAsync();
      this.currentSound = null;
    }

    // Final sync
    await this.syncSessionToAPI();

    // Complete session on API
    if (this.session) {
      await fetch(`${process.env.API_URL}/tours/sessions/${this.session.sessionId}/complete`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          endTime: new Date(),
          completionRate: (this.session.waypointsVisited.length / this.waypoints.length) * 100
        })
      });
    }

    this.session = null;
  }

  async pauseAudio() {
    if (this.currentSound) {
      await this.currentSound.pauseAsync();
    }
  }

  async resumeAudio() {
    if (this.currentSound) {
      await this.currentSound.playAsync();
    }
  }

  getProgress(): number {
    if (!this.session || this.waypoints.length === 0) return 0;
    return (this.session.waypointsVisited.length / this.waypoints.length) * 100;
  }
}
```

### 10.3 Offline Mode Support

```typescript
// mobile-app/src/services/OfflineManager.ts

import NetInfo from '@react-native-community/netinfo';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as FileSystem from 'expo-file-system';

export class OfflineManager {
  private isOnline: boolean = true;
  private pendingActions: Array<any> = [];

  async initialize() {
    // Monitor network status
    NetInfo.addEventListener(state => {
      this.isOnline = state.isConnected ?? false;
      
      if (this.isOnline) {
        this.processPendingActions();
      }
    });

    // Load pending actions
    const stored = await AsyncStorage.getItem('pending_actions');
    if (stored) {
      this.pendingActions = JSON.parse(stored);
    }
  }

  async downloadTourContent(tourId: string, waypoints: Waypoint[]) {
    const dir = `${FileSystem.documentDirectory}tours/${tourId}/`;
    
    // Create directory
    await FileSystem.makeDirectoryAsync(dir, { intermediates: true });

    // Download all audio files
    for (const waypoint of waypoints) {
      const audioFileName = `waypoint_${waypoint.id}.mp3`;
      const localPath = `${dir}${audioFileName}`;

      try {
        await FileSystem.downloadAsync(waypoint.narrationAudioUrl, localPath);
        
        // Update waypoint with local path
        waypoint.narrationAudioUrl = localPath;
      } catch (error) {
        console.error(`Failed to download audio for ${waypoint.name}:`, error);
      }
    }

    // Save tour data locally
    await AsyncStorage.setItem(
      `tour_${tourId}`,
      JSON.stringify({ tourId, waypoints })
    );

    return waypoints;
  }

  async queueAction(action: any) {
    this.pendingActions.push(action);
    await AsyncStorage.setItem('pending_actions', JSON.stringify(this.pendingActions));
  }

  private async processPendingActions() {
    while (this.pendingActions.length > 0 && this.isOnline) {
      const action = this.pendingActions.shift();
      
      try {
        await this.executeAction(action);
      } catch (error) {
        // Put back in queue if failed
        this.pendingActions.unshift(action);
        break;
      }
    }

    await AsyncStorage.setItem('pending_actions', JSON.stringify(this.pendingActions));
  }

  private async executeAction(action: any) {
    // Execute API call that was queued
    const response = await fetch(action.url, {
      method: action.method,
      headers: action.headers,
      body: action.body
    });

    if (!response.ok) {
      throw new Error('Action failed');
    }
  }
}
```

---

## 11. CRITICAL MISSING COMPONENTS

### 11.1 File Upload Handler

```typescript
// services/api/src/utils/fileUpload.ts

import multer from 'multer';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import sharp from 'sharp';
import crypto from 'crypto';

const s3Client = new S3Client({
  region: process.env.AWS_REGION!,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!
  }
});

// Memory storage for processing before S3 upload
const storage = multer.memoryStorage();

export const upload = multer({
  storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept images only
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

export async function uploadToS3(
  file: Express.Multer.File,
  folder: string
): Promise<string> {
  // Generate unique filename
  const hash = crypto.randomBytes(16).toString('hex');
  const ext = file.originalname.split('.').pop();
  const filename = `${hash}.${ext}`;
  const key = `${folder}/${filename}`;

  // Optimize image
  const optimized = await sharp(file.buffer)
    .resize(1920, 1080, { fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 85 })
    .toBuffer();

  // Upload to S3
  await s3Client.send(
    new PutObjectCommand({
      Bucket: process.env.S3_BUCKET!,
      Key: key,
      Body: optimized,
      ContentType: 'image/jpeg',
      ACL: 'public-read'
    })
  );

  // Return CDN URL
  return `https://${process.env.CDN_DOMAIN}/${key}`;
}

// Route handler example
import express from 'express';
const router = express.Router();

router.post('/inspection/:bookingId/photos', upload.array('photos', 10), async (req, res) => {
  try {
    const files = req.files as Express.Multer.File[];
    const bookingId = req.params.bookingId;

    const urls = await Promise.all(
      files.map(file => uploadToS3(file, `inspections/${bookingId}`))
    );

    res.json({ success: true, urls });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### 11.2 Computer Vision for Damage Detection

```typescript
// services/api/src/services/DamageDetectionService.ts

import { RekognitionClient, DetectLabelsCommand } from '@aws-sdk/client-rekognition';

export class DamageDetectionService {
  private rekognition: RekognitionClient;

  constructor() {
    this.rekognition = new RekognitionClient({
      region: process.env.AWS_REGION!
    });
  }

  async analyzeDamage(imageUrl: string): Promise<{
    hasDamage: boolean;
    confidence: number;
    damageType?: string;
    description?: string;
  }> {
    // Download image
    const response = await fetch(imageUrl);
    const imageBuffer = Buffer.from(await response.arrayBuffer());

    // Detect labels
    const command = new DetectLabelsCommand({
      Image: { Bytes: imageBuffer },
      MaxLabels: 20,
      MinConfidence: 70
    });

    const result = await this.rekognition.send(command);

    // Check for damage indicators
    const damageKeywords = [
      'Dent', 'Scratch', 'Crack', 'Broken', 'Damaged',
      'Shattered', 'Chipped', 'Torn', 'Puncture'
    ];

    let hasDamage = false;
    let maxConfidence = 0;
    let damageType = '';

    for (const label of result.Labels || []) {
      if (damageKeywords.some(keyword => label.Name?.includes(keyword))) {
        hasDamage = true;
        if ((label.Confidence || 0) > maxConfidence) {
          maxConfidence = label.Confidence || 0;
          damageType = label.Name || '';
        }
      }
    }

    return {
      hasDamage,
      confidence: maxConfidence,
      damageType: hasDamage ? damageType : undefined,
      description: hasDamage ? `Potential ${damageType.toLowerCase()} detected` : 'No damage detected'
    };
  }

  async compareImages(beforeUrl: string, afterUrl: string): Promise<{
    newDamage: boolean;
    differences: string[];
  }> {
    // Compare vehicle condition before and after rental
    // This is a simplified example - production would use more sophisticated comparison
    
    const before = await this.analyzeDamage(beforeUrl);
    const after = await this.analyzeDamage(afterUrl);

    return {
      newDamage: after.hasDamage && !before.hasDamage,
      differences: after.hasDamage ? [after.description!] : []
    };
  }
}
```

### 11.3 Revenue Split Calculator

```typescript
// services/api/src/services/RevenueCalculator.ts

interface Partner {
  id: string;
  tier: 'tier1' | 'tier2' | 'tier3';
  revenueSplit: number; // Percentage
}

interface Booking {
  totalPrice: number;
  vehicleId: string;
  platformFees: number;
  stripeProcessingFee: number;
}

export class RevenueCalculator {
  calculateSplit(booking: Booking, partner: Partner) {
    const grossRevenue = booking.totalPrice;
    
    // Deduct platform operating costs
    const stripeeFee = booking.stripeProcessingFee || (grossRevenue * 0.029 + 0.30);
    const platformFee = booking.platformFees || (grossRevenue * 0.05); // 5% platform fee
    
    // Net revenue after costs
    const netRevenue = grossRevenue - stripeeFee - platformFee;
    
    // Split based on partner tier
    const partnerShare = netRevenue * (partner.revenueSplit / 100);
    const tavxShare = netRevenue - partnerShare;
    
    return {
      grossRevenue,
      costs: {
        stripe: stripeeFee,
        platform: platformFee,
        total: stripeeFee + platformFee
      },
      netRevenue,
      split: {
        partner: partnerShare,
        tavx: tavxShare
      },
      splitPercentage: {
        partner: partner.revenueSplit,
        tavx: 100 - partner.revenueSplit
      }
    };
  }

  calculateMonthlyPayout(partnerId: string, month: number, year: number) {
    // Query all completed bookings for partner's vehicles in the month
    // Calculate cumulative revenue split
    // Generate payout report
  }
}
```

---

## 12. DEVELOPMENT WORKFLOW

### 12.1 Repository Structure

```
tavx-platform/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── deploy-staging.yml
│       └── deploy-production.yml
├── services/
│   ├── booking-service/
│   │   ├── src/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── vehicle-service/
│   ├── tour-service/
│   ├── payment-service/
│   └── shared/
│       ├── types/
│       ├── utils/
│       └── clients/
├── mobile-app/
│   ├── src/
│   ├── assets/
│   ├── app.json
│   └── package.json
├── web-portal/
│   ├── src/
│   ├── public/
│   └── package.json
├── infrastructure/
│   ├── terraform/
│   ├── k8s/
│   └── docker-compose.yml
├── scripts/
│   ├── setup-dev.sh
│   ├── seed-database.ts
│   └── setup-vapi.ts
├── docs/
│   ├── API.md
│   ├── DEPLOYMENT.md
│   └── CONTRIBUTING.md
├── .env.example
├── .gitignore
├── package.json
└── README.md
```

### 12.2 Git Workflow

```bash
# Feature branch workflow

# 1. Create feature branch
git checkout -b feature/voice-checkin-flow

# 2. Make changes and commit
git add .
git commit -m "feat(voice): implement voice-guided check-in"

# 3. Push and create PR
git push origin feature/voice-checkin-flow

# 4. After review and CI passes, merge to main
# GitHub Actions automatically deploys to staging

# 5. After QA on staging, create release
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0

# GitHub Actions deploys to production
```

### 12.3 CI/CD Pipeline

```yaml
# .github/workflows/ci.yml

name: CI

on:
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
        
    - name: Install dependencies
      run: |
        cd services/booking-service
        npm ci
        
    - name: Run tests
      run: |
        cd services/booking-service
        npm test
        
    - name: Run linter
      run: |
        cd services/booking-service
        npm run lint

  build:
    runs-on: ubuntu-latest
    needs: test
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: |
        docker build -t tavx/booking-service:${{ github.sha }} \
          services/booking-service
    
    - name: Push to registry
      run: |
        echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
        docker push tavx/booking-service:${{ github.sha }}
```

---

## 13. FINAL CHECKLIST FOR CLAUDE CODE

### 13.1 Phase 1 Implementation (MVP - 8 weeks)

**Week 1-2: Foundation**
- [ ] Set up repository structure
- [ ] Configure development environment (Docker Compose)
- [ ] Create Airtable base with all tables
- [ ] Implement authentication system (JWT)
- [ ] Set up API gateway (Kong)
- [ ] Configure CI/CD pipeline

**Week 3-4: Core Backend**
- [ ] Implement Booking Service (availability, creation, management)
- [ ] Implement Vehicle Service (Tesla API integration)
- [ ] Implement Payment Service (Stripe integration)
- [ ] Set up Redis caching
- [ ] Configure RabbitMQ message queue
- [ ] Implement notification service (Twilio/SendGrid)

**Week 5-6: Voice & Tour Systems**
- [ ] Set up Vapi voice agents (check-in/check-out)
- [ ] Implement voice function handlers
- [ ] Create tour content in Airtable
- [ ] Build tablet app (React Native)
- [ ] Implement GPS tracking and geofencing
- [ ] Audio playback system with offline support

**Week 7-8: Frontend & Testing**
- [ ] WordPress booking portal
- [ ] Operator dashboard (Retool or React)
- [ ] End-to-end testing
- [ ] User acceptance testing
- [ ] Performance testing
- [ ] Deploy to staging

### 13.2 Critical Environment Variables

```bash
# .env.example

# Application
NODE_ENV=development
API_URL=http://localhost:3000
PORT=3000

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/tavx
REDIS_URL=redis://localhost:6379
QDRANT_URL=http://localhost:6333

# Authentication
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=7d

# External APIs
TESLA_API_TOKEN=your-tesla-api-token
STRIPE_SECRET_KEY=sk_test_your-stripe-key
STRIPE_PUBLISHABLE_KEY=pk_test_your-stripe-key
STRIPE_WEBHOOK_SECRET=whsec_your-webhook-secret

TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+15105551234

VAPI_API_KEY=your-vapi-api-key
VAPI_CHECKIN_ASSISTANT_ID=asst_xxxxx
VAPI_CHECKOUT_ASSISTANT_ID=asst_xxxxx

VOICEMAP_API_KEY=your-voicemap-key

GOOGLE_MAPS_API_KEY=your-google-maps-key

# AWS
AWS_REGION=us-west-2
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
S3_BUCKET=tavx-uploads
CDN_DOMAIN=cdn.tavx.com

# Airtable (Phase 1)
AIRTABLE_API_KEY=your-airtable-key
AIRTABLE_BASE_ID=appXXXXXXXXXX

# Monitoring
SENTRY_DSN=your-sentry-dsn
GRAFANA_PASSWORD=your-grafana-password

# n8n
N8N_USER=admin
N8N_PASSWORD=your-n8n-password
```

### 13.3 Quick Start Commands

```bash
# Clone repository
git clone https://github.com/tavx/platform.git
cd platform

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your values

# Start development environment
docker-compose up -d

# Run database migrations
npm run migrate

# Seed database with sample data
npm run seed

# Start all services
npm run dev

# Run tests
npm test

# Build for production
npm run build

# Deploy to staging
npm run deploy:staging
```

---

## 14. SUCCESS METRICS & MONITORING

### 14.1 Key Performance Indicators

**Operational Metrics:**
- Average check-in time: < 5 minutes
- Average check-out time: < 5 minutes
- Voice AI success rate: > 95%
- Tour completion rate: > 90%
- Vehicle utilization: > 85%
- System uptime: 99.9%

**Business Metrics:**
- Monthly bookings growth: 20% MoM
- Average booking value: $500+
- Customer acquisition cost: < $50
- Customer lifetime value: $1,500+
- Net promoter score: > 50
- Revenue per vehicle: $40K+ annually

**Technical Metrics:**
- API response time (p95): < 200ms
- API response time (p99): < 500ms
- Error rate: < 0.1%
- Database query time: < 50ms
- File upload time: < 3 seconds

### 14.2 Alert Configuration

```yaml
# prometheus/alerts.yml

groups:
  - name: tavx_alerts
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "High error rate detected"
          
      - alert: SlowAPIResponse
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 10m
        annotations:
          summary: "API response time is slow"
          
      - alert: LowVehicleUtilization
        expr: avg(vehicle_utilization_percent) < 70
        for: 1h
        annotations:
          summary: "Fleet utilization below target"
          
      - alert: DatabaseConnectionIssue
        expr: up{job="postgres"} == 0
        for: 1m
        annotations:
          summary: "Database is down"
          
      - alert: TeslaAPIFailure
        expr: rate(tesla_api_errors_total[5m]) > 0.1
        for: 5m
        annotations:
          summary: "Tesla API experiencing issues"
```

---

## 15. CONCLUSION & NEXT STEPS

This comprehensive specification provides Claude Code with everything needed to architect and build the TAV-X system from scratch. The architecture is designed to:

1. **Scale efficiently** from 10 to 1000+ vehicles
2. **Maintain high availability** (99.9% uptime)
3. **Support offline operation** for critical tour features
4. **Ensure data integrity** with ACID-compliant transactions
5. **Provide real-time updates** via WebSocket
6. **Integrate seamlessly** with external APIs
7. **Monitor comprehensively** with metrics and logging
8. **Deploy confidently** with CI/CD automation

**Immediate Actions:**
1. Set up repository and development environment
2. Create Airtable base with schema from Part 1
3. Configure all external API accounts (Tesla, Stripe, Twilio, Vapi)
4. Implement core Booking Service
5. Build MVP of voice-guided check-in
6. Develop tablet app with GPS tour tracking

**Success Criteria:**
- Successfully complete 50+ rentals in first 3 months
- Achieve 90%+ customer satisfaction rating
- Maintain < 5 minute check-in/out times
- 85%+ vehicle utilization rate
- Zero data breaches or security incidents

The system is production-ready when all Phase 1 components are deployed, tested, and monitored with the specifications outlined in this document.

