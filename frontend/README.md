# SafeHer AI — Flutter Android Frontend

**Interactive Women-Safety Route-Planning & Navigation Mobile Client**

The SafeHer AI frontend is a cross-platform mobile application built using **Flutter and Dart**, optimized for Android devices. It enables women in Hyderabad to search destinations, compare route safety profiles, view turn-by-turn navigation with live GPS updates, find nearby emergency amenities, and access immediate SOS alerts.

> [!IMPORTANT]
> **Safety Disclaimer:**  
> The safety evaluations and route recommendations provided by this app are analytical estimates meant for decision support. They are not an absolute guarantee of safety. In emergencies, call **100**, **112**, **181**, or **9490616555** directly.

---

## Deployed Backend Connection

The Flutter application connects by default to the deployed cloud backend on Render:

| Endpoint | Target URL |
|---|---|
| **API Base URL** | `https://safeherai-4baw.onrender.com` |
| **Health Check** | `https://safeherai-4baw.onrender.com/health` |
| **API Docs (Swagger)** | `https://safeherai-4baw.onrender.com/docs` |

### Configuring the API URL

The backend API endpoint is defined in [`lib/constants/app_constants.dart`](lib/constants/app_constants.dart):

```dart
class AppConstants {
  // Production Cloud Backend on Render
  static const String defaultApiUrl = 'https://safeherai-4baw.onrender.com';
  
  // Local Development Loopback
  static const String localApiUrl = 'http://localhost:8000';
  ...
}
```

- **Production / Physical Android Device:** Uses `https://safeherai-4baw.onrender.com` (default).
- **Android Studio Emulator:** Can point to `http://10.0.2.2:8000` when running a local FastAPI server.
- **Local Network Testing:** Can point to `http://<YOUR_LAN_IP>:8000`.

> [!NOTE]
> On Render's free tier, the backend spins down after 15 minutes of inactivity. When opening the app after an idle period, the first request may take 30–50 seconds to respond as the cloud container starts up.

---

## Implemented Screens Catalog (20 Screens)

SafeHer AI includes 20 screens implemented in [`lib/screens/`](lib/screens/):

| Screen | File | Functionality & Features |
|---|---|---|
| **Splash** | `splash_screen.dart` | App initialization, branding animation, token validation. |
| **Login** | `login_screen.dart` | Firebase Auth email/password login + Guest Demo access. |
| **Register** | `register_screen.dart` | User registration with input validation. |
| **Home Map** | `home_map_screen.dart` | Interactive map view, quick amenity filters, search bar, SOS floating trigger. |
| **Route Planning** | `route_planning_screen.dart` | Origin/Destination input, landmark autocomplete, live GPS button, recent routes. |
| **Route Comparison**| `route_comparison_screen.dart` | Side-by-side alternative route comparison cards with safety scores and badges. |
| **Safety Breakdown**| `safety_breakdown_screen.dart` | Detailed 7-factor safety score breakdown, radar/bar indicators, spatial context. |
| **Active Journey** | `active_journey_screen.dart` | Turn-by-turn navigation HUD, live GPS marker, bearing rotation, off-route detection. |
| **Journey Report** | `journey_report_screen.dart` | Post-trip summary, safety ratings, feedback submission to backend. |
| **Emergency SOS** | `sos_screen.dart` | One-tap distress trigger, nearest police station finder, direct helpline dialer. |
| **Nearby Amenities**| `nearby_amenities_screen.dart` | Search police stations, emergency hospitals, and metro/bus transit stops. |
| **Profile** | `profile_screen.dart` | User information overview, settings navigation, logout. |
| **Personal Info** | `personal_info_screen.dart` | Edit user profile, display name, and emergency contact phone number. |
| **Journey History** | `journey_history_screen.dart` | Browse completed trips, departure dates, route summaries, and recorded scores. |
| **Journey Details** | `journey_details_screen.dart` | Detailed view of historical trips with safety factor analysis. |
| **Trusted Contacts**| `trusted_contacts_screen.dart`| Add, view, edit, and delete trusted emergency contacts. |
| **Safety Emergency**| `safety_emergency_screen.dart`| Comprehensive emergency contact directory and tactical guidance tips. |
| **Settings** | `settings_screen.dart` | Configure audio cues, route preference filters, notification triggers. |
| **Privacy Policy** | `privacy_screen.dart` | In-app transparency documentation detailing location handling and telemetry. |
| **About SafeHer** | `about_screen.dart` | Academic credits, 7-factor methodology summary, legal disclaimers. |

---

## Live GPS Tracking & Navigation Architecture

The app uses `geolocator` and `flutter_compass` to provide real-time navigation:
- **Continuous Position Streaming**: Listens to Android location updates with high accuracy settings.
- **Dynamic Bearing Calculation**: Updates camera orientation and directional arrow icon based on device movement vectors.
- **Noise Filtering**: Ignores GPS jitter under 1.5 meters to conserve battery and avoid marker oscillation.
- **Turn-by-Turn Maneuver HUD**: Shows upcoming turn icons (sharp left, slight right, keep straight), distance countdown, and street names.
- **Dynamic Off-Route Recalculation**: Detects when the user deviates > 60 meters from the planned corridor and automatically triggers rerouting.

---

## Android Permissions

Declared in [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml):

| Permission | Purpose |
|---|---|
| `android.permission.INTERNET` | Communicates with the FastAPI backend and map tile servers. |
| `android.permission.ACCESS_FINE_LOCATION` | Required for precise GPS navigation, route planning, and SOS coordinates. |
| `android.permission.ACCESS_COARSE_LOCATION` | Fallback approximate cell/WiFi tower location. |
| `android.permission.CALL_PHONE` | Allows direct one-tap dialing of emergency helplines from the SOS screen. |

---

## Prerequisites & Development Setup

- **Flutter SDK**: 3.x (verified on Flutter 3.47.6 • channel stable)
- **Dart SDK**: 3.x (verified on Dart 3.13.5)
- **Android SDK**: API level 28+ (Android 9.0 Pie or newer)
- **Java / JDK**: OpenJDK 17 or 21

### 1. Install Dependencies
```powershell
cd C:\SafeHerAI\frontend
flutter pub get
```

### 2. Run Static Analysis
```powershell
flutter analyze
```
*(Code is verified with 0 errors and 0 warnings).*

### 3. Run Automated Tests
```powershell
flutter test
```
*Executes all 11 unit and widget tests in `test/widget_test.dart`.*

### 4. Run the App Locally
```powershell
# Run on an attached physical device or emulator
flutter run
```

---

## Building the Release APK

The production release APK is built using Flutter's Gradle packaging toolchain:

```powershell
cd C:\SafeHerAI\frontend
flutter build apk --release
```

- **Output Location:**  
  `frontend/build/app/outputs/flutter-apk/app-release.apk`
- **Binary Size:** ~56.0 MB (58,692,066 bytes)
- **Install on Device via ADB:**
  ```powershell
  adb install -r build\app\outputs\flutter-apk\app-release.apk
  ```

---

## Mapping Configuration & Fallback Engine

SafeHer AI supports dual mapping modes:
1. **Built-in SafeHer Canvas Map (Default / Demo Mode):**
   - Renders routes, markers, safe spots, and polylines on an internal canvas.
   - **Requires zero API keys or Google Cloud billing**.
   - Activated automatically if no Google Maps API key is configured.
2. **Google Maps SDK (Optional Live Mode):**
   - To activate satellite tiles or Google Maps SDK rendering, provide an API key in `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_GOOGLE_MAPS_KEY_HERE"/>
     ```

---

## Troubleshooting Frontend Issues

1. **"Failed to connect to backend" or "Connection refused":**
   - Verify device has active WiFi or Mobile Data.
   - Open Chrome on the device and visit `https://safeherai-4baw.onrender.com/health`. If the server is waking from sleep, wait ~40 seconds and refresh.
   - If developing locally, ensure the phone is on the same local network as your PC and using your PC's IP, or use `adb reverse tcp:8000 tcp:8000`.
2. **Current Location Button Doesn't Respond:**
   - Verify Android Location / GPS is toggled ON in device quick settings.
   - Ensure the app was granted **"Precise location"** permission in App Settings.
3. **App Crashes on Dialing Helplines:**
   - Confirm `CALL_PHONE` permission was granted when prompted. The SOS screen will open the system dialer with the helpline pre-filled if direct call is restricted.
