# SafeHer AI

**Women-Safety Route Recommendation System — Hyderabad, India**

SafeHer AI is a full-stack Android mobile application that helps women navigate Hyderabad more safely by evaluating routes using verified spatial infrastructure data (police stations, emergency hospitals, public transit, road networks, accident black spots) and official Hyderabad City Police annual crime statistics. Routes are ranked by a multi-criteria safety scoring engine and presented alongside real-time emergency tools.

> **Safety Disclaimer:** Safety scores produced by SafeHer AI are comparative route estimates intended as decision-support information. They are **not** a guarantee of personal safety.

---

## Current Project Status

| Area | Status |
|---|---|
| FastAPI backend | Complete MVP |
| Safety-scoring engine | Implemented and tested |
| Backend tests | **44 / 44 passing** |
| Flutter tests | **5 / 5 passing** |
| Android debug APK | Successfully built and launched |
| Android release APK | Successfully built (~53.5 MB) |
| Firebase Auth / Firestore | Configured and tested |
| Google Maps live API | Optional — not currently configured; demo-map fallback active |
| iOS | Not built — macOS + Xcode required |

---

## Project Structure

```
SafeHerAI/
+-- backend/
|   +-- app/
|   |   +-- api/          routes.py  (all REST endpoints)
|   |   +-- core/         config.py
|   |   +-- ml/           safety_scorer.py, spatial_features.py,
|   |   |                 normalization.py, config.py, demo_scoring.py
|   |   +-- schemas/      route, safety, navigation, amenity, sos, user, journey
|   |   +-- services/     navigation, route, amenities, sos, auth, journey
|   |   +-- static/
|   |   +-- main.py
|   +-- tests/            44 unit + integration tests
|   +-- requirements.txt
+-- frontend/
|   +-- lib/
|   |   +-- constants/    app_constants.dart  (colors, URLs, helplines)
|   |   +-- models/       route, amenity, sos, user, journey models
|   |   +-- providers/    AuthProvider, RouteProvider, SOSProvider, JourneyProvider
|   |   +-- screens/      20 screens (see Flutter Screens section)
|   |   +-- services/     ApiService, FirebaseService
|   |   +-- widgets/      SafetyBadge, SOSButton, SafeHerDemoMap
|   |   +-- main.dart
|   +-- android/          AndroidManifest.xml, google-services.json
|   +-- pubspec.yaml
+-- datasets/             Verified Hyderabad spatial datasets (see Datasets section)
+-- docs/
|   +-- ml_methodology.md
+-- firebase-service-account.json   (NOT committed -- see Secrets section)
+-- .env.example
+-- .gitignore
```

---

## Technology Stack

| Component | Technology |
|---|---|
| Mobile App | Flutter 3.x (Dart) |
| Backend API | Python 3.12 + FastAPI |
| Safety-Scoring Engine | NumPy, SciPy, Shapely -- multi-criteria weighted scoring |
| Maps (Demo Mode) | SafeHer AI built-in canvas demo map (no API key required) |
| Maps (Live Mode) | Google Maps Flutter SDK + Google Directions / Places / Geocoding APIs |
| Authentication | Firebase Authentication (Email/Password) + Firebase Admin SDK |
| Cloud Storage | Firebase Cloud Firestore (journeys, SOS events, feedback) |
| Spatial Data | GeoJSON, CSV -- genuine Hyderabad datasets |

---

## Safety-Scoring Engine

The core scoring engine evaluates routes using **7 weighted multi-criteria factors**, each grounded in verified Hyderabad spatial data. It does not use a pre-trained machine learning model; the score is computed analytically from spatial proximity and infrastructure density measurements.

| Factor | Weight | Data Source |
|---|---|---|
| Police Accessibility | 25% | Hyderabad City Police station locations |
| Emergency Medical Proximity | 15% | GHMC / NMC hospital registry |
| Public Transit Density | 15% | HMRL Metro + TSRTC bus stops |
| Arterial Road Hierarchy | 15% | OpenStreetMap road classifications |
| Jurisdictional Crime Volume | 15% | Hyderabad City Police Annual Reviews |
| Accident Black Spot Avoidance | 10% | GHMC / HMDA identified junctions |
| Route Efficiency / Directness | 5% | Detour ratio computation |

**Score Tiers:**

| Range | Tier |
|---|---|
| 75 - 100 | Comparatively Safer Route |
| 50 - 74.9 | Moderate Safety Corridor |
| 0 - 49.9 | Caution Advised Corridor |

> Weights are project-defined analytical parameters for comparative route evaluation. They are not official government safety ratings.

---

## Datasets

All datasets are genuine non-synthetic data curated for Hyderabad, India. They are loaded once at backend startup and are not regenerated at runtime.

```
datasets/
+-- police_stations.geojson        Hyderabad City Police station locations
+-- hospitals.csv                  GHMC / NMC emergency hospital registry
+-- transport_stations.csv         HMRL Metro + TSRTC bus/transit stops
+-- crime_data.csv                 Official police zone crime statistics
+-- hyderabad_women_safety.csv     Women-safety zone data
+-- area_zone_mapping.csv          Area-to-police-zone mapping
+-- road_accidents.csv             GHMC / HMDA accident black spots
+-- demographics.csv               Area demographic context data
+-- roads/
|   +-- hyderabad_major_roads.geojson   Arterial road network (OSM)
+-- boundaries/
|   +-- ghmc_zones.kml             GHMC administrative zone boundaries
+-- journey_feedback.csv           Accumulated journey feedback (observational)
+-- DATA_SOURCES.md                Full provenance and attribution
```

> **Note:** No micro-level GPS crime coordinates are published. Indian law and police practices prohibit publishing precise crime locations for offences against women. Crime data is aggregated by police zone from official annual reviews.

---

## Prerequisites

### Backend
- Python 3.10+ (tested on 3.12)
- pip

### Flutter / Android
- Flutter SDK 3.0+
- Android Studio or VS Code with Flutter extension
- Android device or emulator (API 28+)

### Optional (Full Feature Set)
- Google Maps API key with Directions, Places, and Geocoding APIs enabled (for live mapping)
- Firebase project with Email/Password Authentication enabled

---

## Setup -- Backend

```powershell
# Navigate to the project root
cd C:\SafeHerAI

# Navigate to backend
cd backend

# Create a Python virtual environment
python -m venv venv

# Activate (PowerShell)
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# (Optional) Configure environment variables
# Copy .env.example to .env and set values as needed
# $env:FIREBASE_CREDENTIALS_PATH = "C:\SafeHerAI\firebase-service-account.json"
# $env:GOOGLE_MAPS_API_KEY = "your_key_here"

# Start the FastAPI backend (from project root)
cd C:\SafeHerAI
uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

Once running:
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **Health Check:** http://localhost:8000/health

---

## Setup -- Flutter Frontend

```powershell
# Navigate to the frontend directory
cd C:\SafeHerAI\frontend

# Get Flutter dependencies
flutter pub get

# Firebase Android configuration
# 1. Create a Firebase project at https://console.firebase.google.com
# 2. Enable Email/Password Authentication under Authentication > Sign-in method
# 3. Download google-services.json and place it at:
#    frontend/android/app/google-services.json

# Google Maps (optional -- app works without it in demo mode)
# Add your API key to frontend/android/app/src/main/AndroidManifest.xml:
# <meta-data android:name="com.google.android.geo.API_KEY"
#            android:value="YOUR_KEY_HERE"/>

# Run on a connected device or emulator
flutter run --device-id emulator-5554 --debug
```

> The app includes a **SafeHer AI demo map** that renders without a Google Maps API key, allowing full demonstration of route planning, safety scoring, and all screens without billing configuration.

---

## Running Tests

### Backend Tests (44 / 44)

```powershell
cd C:\SafeHerAI

# Activate backend virtual environment first
cd backend
.\venv\Scripts\Activate.ps1
cd ..

# Run all backend tests
python -m unittest discover -s backend/tests -p "test_*.py"
```

Expected output: **44 tests passing** (ML unit tests + API integration tests + journey pipeline tests)

### Flutter Tests (5 / 5)

```powershell
cd C:\SafeHerAI\frontend
flutter test
```

Expected output: **5 tests passing**

---

## Building the Android Release APK

```powershell
cd C:\SafeHerAI\frontend
flutter build apk --release
```

Output: `frontend/build/app/outputs/flutter-apk/app-release.apk` (~53.5 MB)

The release APK has been successfully built and tested on an Android emulator (API 37 / 1080 x 2400).

---

## iOS

Flutter is a cross-platform framework and the project can be targeted at iOS. However, **building, signing, and testing the iOS application requires macOS and Xcode**. The iOS version has not been built or tested in this project.

---

## API Endpoints

### Health

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Backend health check |

### Safety Scoring

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/safety/score` | Score a route polyline (7-factor breakdown) |
| GET | `/api/v1/safety/nearby-safe-spots` | Find nearest police, hospitals, transit by GPS |

### Navigation and Routing

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/routes/plan` | Plan and compare multi-route safety alternatives |
| GET | `/api/v1/places/autocomplete` | Search Hyderabad places and landmarks |

### Authentication

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Register new user (legacy / fallback) |
| POST | `/api/v1/auth/login` | Authenticate user (legacy / fallback) |
| POST | `/api/v1/auth/firebase` | Exchange Firebase ID token for session |
| PUT | `/api/v1/user/profile` | Update user display name and emergency phone |

### Emergency SOS and Contacts

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/sos/trigger` | Trigger emergency SOS distress alert |
| GET | `/api/v1/user/contacts` | List trusted emergency contacts |
| POST | `/api/v1/user/contacts` | Add trusted emergency contact |
| PUT | `/api/v1/user/contacts/{id}` | Update trusted contact |
| DELETE | `/api/v1/user/contacts/{id}` | Delete trusted contact |

### Journey Navigation

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/journey/start` | Start an active navigation journey |
| POST | `/api/v1/journey/event` | Log a telemetry or SOS event during a journey |
| POST | `/api/v1/journey/complete` | Complete journey and submit user feedback |
| GET | `/api/v1/journey/feedback` | Retrieve accumulated feedback dataset entries |
| GET | `/api/v1/journey/user` | Retrieve navigation journeys for a user |

---

## Flutter Screens

| Screen | Description |
|---|---|
| SplashScreen | Animated loading and branding |
| LoginScreen | Email/password sign-in + Guest / Demo Mode |
| RegisterScreen | New account creation |
| HomeMapScreen | Main map with demo / live routing, filter chips, profile access |
| RoutePlanningScreen | Origin / destination input with landmark autocomplete |
| RouteComparisonScreen | Side-by-side multi-route safety comparison |
| SafetyBreakdownScreen | Detailed 7-factor safety score breakdown |
| ActiveJourneyScreen | Live navigation view with journey telemetry |
| JourneyReportScreen | Post-journey summary and feedback submission |
| SOSScreen | One-tap emergency alert + direct helpline dialing |
| NearbyAmenitiesScreen | Nearest police stations, hospitals, transit |
| ProfileScreen | User profile menu |
| PersonalInfoScreen | Edit display name and emergency phone |
| JourneyHistoryScreen | Browse past navigation journeys |
| JourneyDetailsScreen | Per-journey metadata, route info, and safety breakdown |
| TrustedContactsScreen | Add, edit, and delete emergency contacts |
| SafetyEmergencyScreen | Emergency helplines + nearby infrastructure links |
| SettingsScreen | Routing and alert preferences |
| PrivacyScreen | Data and privacy policy |
| AboutScreen | App version, methodology, and safety disclaimer |

---

## Firebase Architecture

- **Firebase Authentication** -- Email/Password sign-in. The Flutter app calls `FirebaseAuth.createUserWithEmailAndPassword()` and `signInWithEmailAndPassword()`.
- **Firebase ID Token Exchange** -- After sign-in, the Flutter app obtains a Firebase ID token and sends it to `POST /api/v1/auth/firebase`. The FastAPI backend verifies the token using the **Firebase Admin SDK** with a service-account credential file.
- **Cloud Firestore** -- Used for journey records, SOS events, and feedback persistence. Firestore security rules restrict each user's data to their own authenticated UID.
- **Android Configuration** -- `google-services.json` must be present at `frontend/android/app/google-services.json`.

> SafeHer AI does not store user passwords. Credential management is handled entirely by Firebase Authentication.

---

## Google Maps

Google Maps billing and an API key are **not currently configured** for this project.

The Flutter app detects the missing API key and automatically activates the **SafeHer AI demo map** -- a built-in canvas renderer that displays route planning, safety scores, markers, and polylines without requiring billing.

To enable live Google mapping:
1. Create a project at https://console.cloud.google.com
2. Enable the Maps SDK for Android, Directions API, Places API, and Geocoding API.
3. Create an API key and add it to `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_KEY_HERE" />
   ```
4. Optionally set `GOOGLE_MAPS_API_KEY` in the backend `.env` file for server-side routing.

---

## Emergency SOS

The SafeHer AI SOS system:
- Identifies the closest police station from verified dataset coordinates.
- Notifies registered trusted contacts.
- Provides one-tap dialing of official emergency helplines.
- Logs the SOS event with timestamp and GPS coordinates for user records.

**SafeHer AI does not automatically dispatch police or emergency services.** In an emergency, use the built-in dialer or call directly:

| Service | Number |
|---|---|
| Telangana Police | 100 |
| National Emergency | 112 |
| Women Helpline (All India) | 181 |
| Hyderabad SHE Teams | 9490616555 |
| Ambulance | 108 |

---

## Journey Feedback

When a journey is completed, users can submit an observational safety rating and notes. This feedback is stored in `datasets/journey_feedback.csv` and in Firestore for future analysis and manual validation.

> Submitting journey feedback does **not** automatically retrain or modify the safety-scoring engine.

---

## Environment Variables

See `.env.example` for all available configuration options.

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | Optional | Google Maps, Directions, Places, Geocoding APIs |
| `FIREBASE_PROJECT_ID` | Optional | Firebase project identifier |
| `FIREBASE_CREDENTIALS_PATH` | Optional | Path to Firebase Admin SDK service-account JSON |
| `JWT_SECRET_KEY` | Optional | JWT signing secret (defaults to dev key) |
| `JWT_EXPIRATION_HOURS` | Optional | Token validity in hours (default: 72) |

---

## Secrets -- Never Commit

The following files contain private credentials and are excluded by `.gitignore`:

```
firebase-service-account.json
*-adminsdk-*.json
serviceAccountKey.json
.env
*.env
```

**Never commit API keys, service-account files, or private credentials to version control.**

---

## Data Attribution

All spatial datasets are genuine, non-synthetic data curated for Hyderabad, India.
See `datasets/DATA_SOURCES.md` for full provenance and attribution.

Key sources:
- Hyderabad City Police (Annual Crime Reviews)
- HMRL -- Hyderabad Metro Rail Ltd (station locations)
- GHMC / HMDA (hospital registry, accident black spots)
- OpenStreetMap (road network classification)
- TSRTC (bus terminal locations)

---

## License

Developed for academic and research purposes -- Women Safety and Route Recommendation for Hyderabad, India.
