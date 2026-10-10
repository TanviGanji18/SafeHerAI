# SafeHer AI

**Analytical Women-Safety Route Recommendation & Navigation System — Hyderabad, India**

SafeHer AI is an analytical women-safety and safer route recommendation system designed specifically for Hyderabad, India. The project consists of a full-featured **Flutter (Android) mobile application** and a high-performance **Python FastAPI backend**.

The system evaluates travel routes against genuine spatial infrastructure (police stations, emergency medical hospitals, public transit nodes, classified arterial road corridors, and identified accident black spots) combined with official Hyderabad City Police annual crime statistics. Route alternatives are evaluated, scored across 7 analytical dimensions, and presented to the user with turn-by-turn guidance, live GPS positioning, nearest safety amenities, and one-tap emergency SOS tools.

> [!IMPORTANT]
> **Safety & Legal Disclaimer:**  
> Safety scores and route evaluations produced by SafeHer AI are comparative analytical estimates intended purely as decision-support information. They do **not** constitute an absolute guarantee of personal safety. In an active emergency, users must immediately contact official emergency services (Telangana Police: **100**, National Emergency: **112**, Women Helpline: **181**, or SHE Teams: **9490616555**). SafeHer AI does not automatically dispatch first responders.

---

## Live Deployed Backend & Service Links

The SafeHer AI FastAPI backend is deployed on Render's cloud platform:

| Service | URL | Notes |
|---|---|---|
| **Base API URL** | `https://safeherai-4baw.onrender.com` | Deployed FastAPI Web Service |
| **Health Check** | `https://safeherai-4baw.onrender.com/health` | Returns `{"status":"ok","service":"SafeHer AI backend"}` |
| **Interactive Swagger Docs** | `https://safeherai-4baw.onrender.com/docs` | Live OpenAPI / Swagger UI |
| **ReDoc Documentation** | `https://safeherai-4baw.onrender.com/redoc` | Alternative API reference |
| **Web Client Interface** | `https://safeherai-4baw.onrender.com/` | Serves web client static interface |

> [!NOTE]
> On Render's free tier, backend instances spin down after 15 minutes of inactivity. The first request after an idle period may take 30–50 seconds to cold-start while the container and spatial datasets load into memory. Subsequent calls respond in milliseconds.

---

## Sub-Project Documentation

For component-specific setup and technical guides, refer to:
- 📱 **[Frontend README (Flutter Android)](frontend/README.md)** — App architecture, screen catalog, Android permissions, GPS/bearing tracking, API configuration, and APK build instructions.
- ⚙️ **[Backend README (FastAPI Python)](backend/README.md)** — Backend architecture, spatial dataset loading, route calculation, all 21 REST endpoints, test suites, and Render deployment setup.

---

## Current Project Status

| Area | Status | Verified Details |
|---|---|---|
| **FastAPI Backend** | Production Ready | Deployed on Render; 21 verified endpoints operational |
| **Safety-Scoring Engine** | Verified & Calibrated | 7-factor multi-criteria spatial algorithm strictly summing to 1.000 |
| **Backend Test Suite** | **47 / 47 passing** | Unit tests + integration tests + journey pipeline tests |
| **Flutter Test Suite** | **11 / 11 passing** | Smoke tests, model deserialization, navigation HUD, and GPS tracking |
| **Static Code Analysis** | **0 errors, 0 warnings** | Flutter analyze clean |
| **Android Release APK** | Successfully Built | Built at `frontend/build/app/outputs/flutter-apk/app-release.apk` (~56.0 MB) |
| **Physical Device Test** | Verified | Tested on physical Android phone communicating with deployed Render backend |
| **Live GPS & Navigation** | Operational | Real-time position tracking, bearing calculation, turn-by-turn maneuvers, dynamic off-route recalculation |
| **Firebase Integration** | Optional / Graceful Fallback | Firebase Auth & Firestore synchronization supported when configured; local/guest mode active when absent |
| **Google Maps Live API** | Optional | Offline Hyderabad landmark engine and canvas map provide full fallback if Google API key is omitted |

---

## Repository Structure

```
SafeHerAI/
├── backend/
│   ├── app/
│   │   ├── api/          routes.py (all 21 registered REST endpoints)
│   │   ├── core/         config.py (environment variables, CORS, directory resolution)
│   │   ├── ml/           safety_scorer.py, spatial_features.py, normalization.py, config.py, demo_scoring.py
│   │   ├── schemas/      route.py, safety.py, navigation.py, amenity.py, sos.py, user.py, journey.py
│   │   ├── services/     navigation_service.py, route_service.py, amenities_service.py, sos_service.py, auth_service.py, journey_service.py
│   │   ├── static/       index.html (interactive web preview interface)
│   │   └── main.py       FastAPI entry point, CORS middleware, lifespan events
│   ├── tests/            47 automated unit and integration tests
│   ├── requirements.txt  Pinned production Python dependencies
│   └── README.md         Detailed backend documentation
├── frontend/
│   ├── lib/
│   │   ├── constants/    app_constants.dart (Render API URL, themes, helplines)
│   │   ├── models/       route_model.dart, navigation_model.dart, amenity_model.dart, sos_model.dart, user_model.dart, journey_model.dart
│   │   ├── providers/    auth_provider.dart, route_provider.dart, sos_provider.dart, journey_provider.dart
│   │   ├── screens/      20 implemented Flutter screens
│   │   ├── services/     api_service.dart, firebase_service.dart, location_service.dart
│   │   ├── widgets/      safeher_demo_map.dart, safety_badge.dart, sos_button.dart
│   │   └── main.dart     Flutter entry point and provider registration
│   ├── android/          AndroidManifest.xml (permissions), build configurations
│   ├── test/             widget_test.dart (11 Flutter test cases)
│   ├── pubspec.yaml      Flutter package dependencies and assets
│   └── README.md         Detailed frontend documentation
├── datasets/             Verified genuine Hyderabad spatial datasets
│   ├── police_stations.geojson
│   ├── hospitals.csv
│   ├── transport_stations.csv
│   ├── crime_data.csv
│   ├── hyderabad_women_safety.csv
│   ├── area_zone_mapping.csv
│   ├── road_accidents.csv
│   ├── demographics.csv
│   ├── roads/
│   │   └── hyderabad_major_roads.geojson
│   ├── boundaries/
│   │   └── ghmc_zones.kml
│   ├── journey_feedback.csv
│   └── DATA_SOURCES.md   Complete data provenance and academic attribution
├── docs/                 Extended methodology and spatial documentation
├── .env.example          Environment variable template with safe placeholders
├── .gitignore            Rules excluding keys, .env, and build artifacts
└── README.md             Main repository documentation
```

---

## High-Level Architecture & Request Flow

```
+-------------------------------------------------------------------------------+
|                        Flutter Android Application                            |
|  - Live GPS Stream (Geolocator)         - Turn-by-Turn HUD / Compass          |
|  - Interactive Map & Polylines          - Emergency SOS & Helpline Dialer     |
|  - Places Search & Autocomplete         - Journey Telemetry & Feedback        |
+-------------------------------------------------------------------------------+
                                      │
                         HTTPS Requests / JSON Payloads
                         Base: https://safeherai-4baw.onrender.com
                                      ▼
+-------------------------------------------------------------------------------+
|                         FastAPI Backend (Render)                              |
|  - CORS Security Policy                 - Exception Handling & Validation     |
|  - Navigation & Turn Engine             - Amenities Proximity Engine          |
|  - Authentication (Firebase / JWT)      - Journey & Feedback Service          |
+-------------------------------------------------------------------------------+
                                      │
                   Evaluates Spatial Route Geometries
                                      ▼
+-------------------------------------------------------------------------------+
|                      7-Factor Safety Scoring Engine                           |
|  1. Police Proximity (25%)              5. Jurisdictional Crime (15%)         |
|  2. Emergency Hospitals (15%)           6. Accident Black Spots (10%)         |
|  3. Public Transit Nodes (15%)          7. Route Directness / Detour (5%)     |
|  4. Arterial Roads Hierarchy (15%)                                            |
+-------------------------------------------------------------------------------+
                                      │
                         Pre-loaded at Startup
                                      ▼
+-------------------------------------------------------------------------------+
|                    Genuine Hyderabad Datasets (datasets/)                     |
|  - Telangana Police GeoJSON             - GHMC / NMC Emergency Hospitals      |
|  - HMRL Metro & TSRTC Transit Stops     - Official Police Zone Crime Stats    |
|  - OSM Primary Arterial Road Corridors  - Identified Traffic Black Spots      |
+-------------------------------------------------------------------------------+
```

---

## Safety-Scoring Methodology & Datasets

Rather than relying on black-box or non-transparent predictive models, SafeHer AI utilizes a **multi-criteria analytical spatial model** grounded directly in genuine infrastructure data curated for Hyderabad, India.

### 1. The 7 Weighted Safety Components

All weights sum strictly to **1.000 (100%)**:

| Component | Weight | Mathematical Function | Description |
|---|:---:|---|---|
| **Police Accessibility ($S_{police}$)** | **25%** | Exponential decay with saturation density | Evaluates distance to nearest police station and saturation count within a 1.0 km radius. |
| **Emergency Medical Proximity ($S_{medical}$)** | **15%** | Continuous linear distance decay | Measures access to 24/7 emergency medical facilities within a 3.0 km buffer. |
| **Public Transit Density ($S_{transit}$)** | **15%** | Saturation density per kilometer | Contextual proxy reflecting populated transit corridors (Metro stations and bus stops). |
| **Arterial Road Hierarchy ($S_{arterial}$)** | **15%** | Buffer intersection length ratio | Measures the proportion of the route traversing major, well-lit, high-visibility arterial roads. |
| **Jurisdictional Crime Penalty ($P_{crime}$)** | **15%** | Police zone crime volume penalty | Normalized against Hyderabad City Police zone statistics. |
| **Accident Black Spot Hazard ($P_{blackspot}$)** | **10%** | Proximity count penalty | Identifies proximity to known high-collision traffic accident black spots. |
| **Route Detour & Exposure ($P_{exposure}$)** | **5%** | Detour ratio penalty | Penalizes unnecessary circuitous routing relative to straight-line distance. |

$$\text{Safety Score} = \left( 0.25 S_{police} + 0.15 S_{medical} + 0.15 S_{transit} + 0.15 S_{arterial} + 0.15 (1 - P_{crime}) + 0.10 (1 - P_{blackspot}) + 0.05 (1 - P_{exposure}) \right) \times 100$$

### 2. Qualitative Safety Tiers

| Score Range | Tier Classification | Practical Meaning |
|---|---|---|
| **75.0 – 100.0** | **Comparatively Safer Route** | High police accessibility, frequent transit nodes, along main arterial roads. |
| **50.0 – 74.9** | **Moderate Safety Corridor** | Standard urban infrastructure presence with average emergency coverage. |
| **0.0 – 49.9** | **Caution Advised Corridor** | Isolated sections, lower infrastructure density, or proximity to hazards. |

### 3. Curated Datasets (`datasets/`)

All datasets are real-world, non-synthetic records curated specifically for Hyderabad:
- `police_stations.geojson`: Exact coordinates of Hyderabad City Police stations.
- `hospitals.csv`: Emergency healthcare centers and trauma facilities across Hyderabad.
- `transport_stations.csv`: Hyderabad Metro Rail (HMRL) stations and TSRTC bus stages.
- `roads/hyderabad_major_roads.geojson`: Primary and secondary arterial road corridors extracted from OpenStreetMap.
- `crime_data.csv` & `hyderabad_women_safety.csv`: Official annual crime review data aggregated by police zone.
- `road_accidents.csv`: High-collision accident black spots identified by GHMC / HMDA.
- `journey_feedback.csv`: Accumulated observational feedback collected from user journeys.

---

## Local Development Prerequisites

- **Backend**:
  - Python 3.10 to 3.12 (tested on Python 3.12.6)
  - `pip` package manager
  - Windows PowerShell, macOS zsh, or Linux bash
- **Frontend**:
  - Flutter SDK 3.x (tested on Flutter 3.47.6 / Dart 3.13.5)
  - Android SDK (API 28+ / Android 9.0+)
  - Android Studio, VS Code, or command-line Android build tools
  - Physical Android device with Developer Mode / USB debugging, or an Android emulator

---

## Local Setup & Startup Instructions

### 1. Setting Up the FastAPI Backend Locally

```powershell
# 1. Clone repository and navigate to backend directory
cd C:\SafeHerAI\backend

# 2. Create and activate a Python virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1    # On Linux/macOS: source venv/bin/activate

# 3. Install required dependencies
pip install -r requirements.txt

# 4. (Optional) Create local configuration
# Copy the root template if custom ports/keys are needed:
Copy-Item ..\.env.example ..\.env

# 5. Start the backend server (binds to 0.0.0.0 for emulator/device access)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verify backend health locally:
- Swagger Docs: `http://localhost:8000/docs`
- Health Endpoint: `http://localhost:8000/health`

### 2. Setting Up the Flutter Frontend

```powershell
# 1. Navigate to frontend directory
cd C:\SafeHerAI\frontend

# 2. Install Flutter packages
flutter pub get

# 3. Verify static analysis
flutter analyze

# 4. Run automated tests
flutter test

# 5. Launch the application on a connected device
flutter run
```

---

## Environment Variables Configuration

The backend reads configuration from environment variables (or `.env` in the root). Never commit sensitive credentials. Placeholders are documented in `.env.example`:

| Variable | Required in Prod? | Example / Default Value | Purpose |
|---|:---:|---|---|
| `HOST` | No | `0.0.0.0` | IP interface to bind to |
| `PORT` | Auto (Render) | `8000` | Server listening port |
| `DEBUG` | Recommended | `False` | Disables verbose debug logging in production |
| `JWT_SECRET_KEY` | **Yes** | `<secure-random-64-character-hex-string>` | Signs internal user authentication tokens |
| `JWT_EXPIRATION_HOURS` | No | `72` | Session duration |
| `ALLOWED_ORIGINS` | Recommended | `*` or `https://safeherai.com` | Comma-separated list of allowed CORS origins |
| `FIREBASE_PROJECT_ID` | Optional | `safeher-ai-491ad` | Firebase Project identifier |
| `FIREBASE_CREDENTIALS_JSON` | Optional | `{"type": "service_account", ...}` | Raw service-account JSON string (for Render) |
| `FIREBASE_CREDENTIALS_PATH` | Optional | `C:\SafeHerAI\firebase-service-account.json` | Path to service-account file (for local dev) |
| `GOOGLE_MAPS_API_KEY` | Optional | `AIzaSy...` | Optional Google Directions/Places key |

---

## Building the Android Release APK

The application has been packaged and verified for physical Android distribution:

```powershell
cd C:\SafeHerAI\frontend
flutter build apk --release
```

- **Actual Release APK Location:**  
  `C:\SafeHerAI\frontend\build\app\outputs\flutter-apk\app-release.apk`
- **Output File Size:** ~56.0 MB (58,692,066 bytes)
- **Pre-configured API URL:** Points to `https://safeherai-4baw.onrender.com`
- **Installation via ADB:**
  ```powershell
  adb install -r frontend\build\app\outputs\flutter-apk\app-release.apk
  ```

---

## Running Test Suites

### Backend Tests (47 passing)
```powershell
cd C:\SafeHerAI\backend
pytest -v
```
*Executes 47 automated tests covering mathematical normalization, safety boundary conditions, route scoring, turn maneuvers, emergency SOS, and journey lifecycle.*

### Frontend Tests (11 passing)
```powershell
cd C:\SafeHerAI\frontend
flutter test
```
*Executes 11 widget and provider tests verifying deserialization, screen rendering, navigation HUD, GPS tracking, and off-route recalculation.*

---

## Emergency SOS & User Safety Features

The SafeHer AI application includes tactical safety mechanisms designed to support women during travel:
- **Nearest Police Station Identification**: Uses real spatial coordinates to locate and display the closest active police facility.
- **Direct Helpline Calling**: One-tap phone launcher for:
  - **100** — Telangana Police
  - **112** — National Emergency
  - **181** — Women Helpline (All India)
  - **9490616555** — Hyderabad SHE Teams
  - **108** — Medical Emergency (Ambulance)
- **Trusted Contacts Management**: Register up to 5 personal emergency contacts stored with local and optional cloud backup.
- **Observational Journey Feedback**: Logs post-journey safety reviews to `datasets/journey_feedback.csv` for empirical analysis.

---

## Troubleshooting & Common Questions

1. **Android App Displays "Connection Error" / Cannot reach backend:**
   - Verify device has active internet access.
   - Test `https://safeherai-4baw.onrender.com/health` in mobile browser. If the free-tier service has spun down, wait 30–45 seconds for cold-start wake-up.
2. **Blue Marker Doesn't Move During Walking:**
   - Ensure Android location permission is set to **"Allow all the time"** or **"While using the app"** with **"Use precise location"** enabled.
   - The app applies GPS noise filtering for movements under 1.5 meters to prevent jitter; walking 5–10 paces triggers updates.
3. **Google Maps Displays Gray Grid / Demo Map Appears:**
   - By design, if no Google Maps API key is configured in `AndroidManifest.xml`, SafeHer AI seamlessly activates the custom canvas demo map without crashing.
4. **Firebase Service Account Not Loading in Cloud:**
   - On Render, do not commit JSON files to Git. Instead, paste the service account contents directly into the `FIREBASE_CREDENTIALS_JSON` environment variable.

---

## Data Attribution & Academic Disclaimer

All spatial datasets used by SafeHer AI are compiled from publicly available government reports, open civic databases, and OpenStreetMap:
- **Hyderabad City Police**: Official Annual Crime Reviews & Zone Boundaries.
- **Hyderabad Metro Rail Ltd (HMRL) & TSRTC**: Transit station locations.
- **Greater Hyderabad Municipal Corporation (GHMC)**: Healthcare facilities and civic accident registries.
- **OpenStreetMap Contributors**: Road network classifications under ODbL.

*Developed for academic, research, and community safety evaluation purposes.*
