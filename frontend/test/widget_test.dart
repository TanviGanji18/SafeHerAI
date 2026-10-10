import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safeher_ai/main.dart';
import 'package:safeher_ai/services/api_service.dart';
import 'package:safeher_ai/providers/auth_provider.dart';
import 'package:safeher_ai/providers/journey_provider.dart';
import 'package:safeher_ai/providers/sos_provider.dart';
import 'package:safeher_ai/screens/profile_screen.dart';
import 'package:safeher_ai/screens/about_screen.dart';
import 'package:safeher_ai/screens/privacy_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safeher_ai/models/journey_model.dart';
import 'package:safeher_ai/models/navigation_model.dart';
import 'package:safeher_ai/models/route_model.dart';
import 'package:safeher_ai/providers/route_provider.dart';
import 'package:safeher_ai/screens/route_planning_screen.dart';
import 'package:safeher_ai/screens/active_journey_screen.dart';
import 'package:safeher_ai/models/user_model.dart';
import 'package:safeher_ai/screens/splash_screen.dart';
import 'package:safeher_ai/screens/login_screen.dart';
import 'package:safeher_ai/services/local_journey_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  testWidgets('SafeHer AI basic app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeHerAIApp());
    expect(find.byType(SafeHerAIApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
  });

  test('ActiveJourney.fromJson deserializes stored journey records properly', () {
    final sampleJson = {
      'journey_id': 'JRN-TEST-001',
      'user_id': 'user_123',
      'origin': {'address': 'Secunderabad'},
      'destination': {'address': 'Charminar'},
      'route_summary': 'MG Road Corridor',
      'distance_km': 11.8,
      'duration_min': 23.0,
      'safety_score': 85.8,
      'safety_tier': 'High Safety Corridor',
      'start_time': '2026-10-07T10:00:00.000Z',
      'journey_status': 'completed',
      'emergency_occurred': false,
    };

    final journey = ActiveJourney.fromJson(sampleJson);
    expect(journey.journeyId, 'JRN-TEST-001');
    expect(journey.originAddress, 'Secunderabad');
    expect(journey.destinationAddress, 'Charminar');
    expect(journey.safetyScore, 85.8);
    expect(journey.distanceKm, 11.8);
    expect(journey.durationMin, 23.0);
    expect(journey.emergencyOccurred, false);
    expect(journey.selectedRoute.contributions.policePts, greaterThan(0));
  });

  testWidgets('ProfileScreen renders user profile, emergency phone, and menu items', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final api = ApiService();
    final auth = AuthProvider(apiService: api);
    final journeyProv = JourneyProvider(apiService: api);
    final sosProv = SOSProvider(apiService: api);

    auth.continueAsGuest();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: journeyProv),
          ChangeNotifierProvider.value(value: sosProv),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Guest Traveler'), findsOneWidget);
    expect(find.text('Guest Mode'), findsOneWidget);
    expect(find.textContaining('emergency phone'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('My Journeys'), findsOneWidget);
    expect(find.text('Trusted Contacts'), findsOneWidget);
    expect(find.text('Safety & Emergency'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About SafeHer AI'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('AboutScreen renders 7 factors and safety disclaimer', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: AboutScreen(),
      ),
    );

    expect(find.text('About SafeHer AI'), findsOneWidget);
    expect(find.text('SafeHer AI'), findsOneWidget);
    expect(find.text('Seven-Factor Contextual Safety Scoring'), findsOneWidget);
    expect(find.text('Important Safety Disclaimer'), findsOneWidget);
  });

  testWidgets('PrivacyScreen renders location and safety policy info', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacyScreen(),
      ),
    );

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Location Information'), findsOneWidget);
    expect(find.text('Authentication & Account Security'), findsOneWidget);
  });

  test('NavigationStep and NavigationRoute deserialize and format icons properly', () {
    final stepJson = {
      'step_index': 1,
      'instruction': 'Turn right onto Tank Bund Rd',
      'maneuver_type': 'turn',
      'modifier': 'right',
      'road_name': 'Tank Bund Rd',
      'distance_meters': 250.0,
      'duration_seconds': 28.0,
      'latitude': 17.4239,
      'longitude': 78.4738,
      'bearing': 90.0,
    };

    final step = NavigationStep.fromJson(stepJson);
    expect(step.stepIndex, 1);
    expect(step.instruction, 'Turn right onto Tank Bund Rd');
    expect(step.maneuverType, 'turn');
    expect(step.modifier, 'right');
    expect(step.distanceMeters, 250.0);
    expect(step.icon, Icons.turn_right_rounded);

    final routeJson = {
      'distance_km': 11.5,
      'duration_min': 22.0,
      'polyline_coords': [
        {'latitude': 17.3616, 'longitude': 78.4747},
        {'latitude': 17.4334, 'longitude': 78.5015},
      ],
      'steps': [stepJson],
      'summary': 'Tank Bund Corridor',
    };

    final navRoute = NavigationRoute.fromJson(routeJson);
    expect(navRoute.distanceKm, 11.5);
    expect(navRoute.durationMin, 22.0);
    expect(navRoute.steps.length, 1);
    expect(navRoute.steps.first.roadName, 'Tank Bund Rd');
  });

  testWidgets('RoutePlanningScreen handles empty defaults, typing, clear buttons, popular routes, and validation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final api = ApiService();
    final routeProv = RouteProvider(apiService: api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: routeProv),
        ],
        child: const MaterialApp(
          home: RoutePlanningScreen(),
        ),
      ),
    );

    // 1. Confirm both fields are empty initially and placeholders are shown
    expect(find.text('Enter starting location'), findsOneWidget);
    expect(find.text('Enter destination'), findsOneWidget);

    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    final originField = textFields.first;
    final destField = textFields.last;

    expect((tester.widget(originField) as TextField).controller!.text, '');
    expect((tester.widget(destField) as TextField).controller!.text, '');
    expect(find.byIcon(Icons.clear), findsNothing);

    // 2. Validate empty submission triggers warning message
    await tester.tap(find.text('FIND SAFER ROUTES'));
    await tester.pump();
    expect(find.text('Please enter both starting location and destination.'), findsOneWidget);

    // 3. Enter custom text in From field and verify clear button appears
    await tester.enterText(originField, 'Mehdipatnam Bus Depot');
    await tester.pump();
    expect((tester.widget(originField) as TextField).controller!.text, 'Mehdipatnam Bus Depot');
    expect(find.byTooltip('Clear starting location'), findsOneWidget);

    // 4. Clear From field using clear button
    await tester.tap(find.byTooltip('Clear starting location'));
    await tester.pump();
    expect((tester.widget(originField) as TextField).controller!.text, '');
    expect(find.byTooltip('Clear starting location'), findsNothing);

    // 5. Enter custom text in To field and verify clear button appears
    await tester.enterText(destField, 'Gachibowli Junction');
    await tester.pump();
    expect((tester.widget(destField) as TextField).controller!.text, 'Gachibowli Junction');
    expect(find.byTooltip('Clear destination'), findsOneWidget);

    // 6. Clear To field using clear button
    await tester.tap(find.byTooltip('Clear destination'));
    await tester.pump();
    expect((tester.widget(destField) as TextField).controller!.text, '');
    expect(find.byTooltip('Clear destination'), findsNothing);

    // 7. Tap a popular route and verify both fields are populated
    final popularRoute = find.text('Gachibowli Junction → Begumpet Airport / Station');
    expect(popularRoute, findsOneWidget);
    await tester.tap(popularRoute);
    await tester.pump();

    expect((tester.widget(originField) as TextField).controller!.text, 'Gachibowli Junction');
    expect((tester.widget(destField) as TextField).controller!.text, 'Begumpet Airport / Station');
    expect(find.byTooltip('Clear starting location'), findsOneWidget);
    expect(find.byTooltip('Clear destination'), findsOneWidget);

    // 8. Verify "Use my current location" quick action is available
    expect(find.text('Use my current location'), findsOneWidget);
  });

  test('JourneyProvider handles navigation steps, off-route detection, and arrival', () async {
    final routeJson = {
      'route_id': 'Route_Safer_1',
      'summary': 'Safer Arterial Corridor',
      'safety_score': 88.5,
      'safety_tier': 'High Safety Corridor',
      'is_recommended_safer': true,
      'is_fastest': false,
      'distance_km': 10.0,
      'duration_min': 20.0,
      'polyline_coords': [
        {'latitude': 17.4300, 'longitude': 78.4500},
        {'latitude': 17.4350, 'longitude': 78.4550},
        {'latitude': 17.4400, 'longitude': 78.4600},
      ],
      'components': {
        'S_police': 80.0,
        'S_medical': 75.0,
        'S_transit': 85.0,
        'S_arterial': 90.0,
        'P_crime': 10.0,
        'P_blackspot': 5.0,
        'P_exposure': 15.0,
      },
      'contributions': {
        'police_pts': 20.0,
        'medical_pts': 15.0,
        'transit_pts': 12.0,
        'arterial_pts': 10.0,
        'crime_compliance_pts': 14.0,
        'blackspot_compliance_pts': 9.0,
        'exposure_compliance_pts': 8.5,
      },
      'raw_features': {
        'avg_police_dist_km': 1.1,
        'police_within_1km_count': 3,
        'min_hospital_dist_km': 0.8,
        'transit_count_within_500m': 5,
        'arterial_length_km': 6.2,
        'traversed_zones': ['Central Zone', 'West Zone'],
        'blackspot_count': 0,
      },
      'steps': [
        {
          'step_index': 0,
          'instruction': 'Head northeast on Main Rd',
          'maneuver_type': 'depart',
          'road_name': 'Main Rd',
          'distance_meters': 500.0,
          'duration_seconds': 60.0,
          'latitude': 17.4300,
          'longitude': 78.4500,
        },
        {
          'step_index': 1,
          'instruction': 'Turn right onto Safety Boulevard',
          'maneuver_type': 'turn',
          'road_name': 'Safety Boulevard',
          'distance_meters': 600.0,
          'duration_seconds': 70.0,
          'latitude': 17.4350,
          'longitude': 78.4550,
        },
        {
          'step_index': 2,
          'instruction': 'You have reached your destination',
          'maneuver_type': 'arrive',
          'road_name': 'Destination Point',
          'distance_meters': 0.0,
          'duration_seconds': 0.0,
          'latitude': 17.4400,
          'longitude': 78.4600,
        },
      ],
    };

    final route = EnrichedRoute.fromJson(routeJson);
    final journeyProv = JourneyProvider(apiService: ApiService());

    // 1. Start journey
    await journeyProv.startJourney(
      route: route,
      origin: {'address': 'Origin'},
      destination: {'address': 'Destination'},
    );

    expect(journeyProv.isNavigating, true);
    expect(journeyProv.remainingDistanceKm, closeTo(10.0, 0.1));
    expect(journeyProv.isDestinationReached, false);
    expect(journeyProv.navigationSteps.length, 3);

    // 2. Simulate location update along corridor
    journeyProv.updateLocation(const LatLng(17.4350, 78.4550));
    expect(journeyProv.isOffRoute, false);

    // 3. Test off-route deviation (> 65m away from polyline)
    journeyProv.updateLocation(const LatLng(17.5000, 78.6000));
    expect(journeyProv.isOffRoute, true);

    // 4. Test arrival at destination (within 65m)
    journeyProv.updateLocation(const LatLng(17.4400, 78.4600));
    expect(journeyProv.isDestinationReached, true);
    expect(journeyProv.currentInstruction, 'Destination Reached!');
  });

  test('Regression test: Navigation maneuver distance is realistic, non-negative, and handles off-route GPS gracefully', () async {
    final routeJson = {
      'route_id': 'test_route_hyd',
      'summary': 'Secunderabad to Charminar Corridor',
      'safety_score': 85.5,
      'safety_tier': 'Comparatively Safer Route',
      'is_recommended_safer': true,
      'is_fastest': false,
      'distance_km': 12.0,
      'duration_min': 23.0,
      'polyline_coords': [
        {'latitude': 17.4334, 'longitude': 78.5015}, // Secunderabad Station
        {'latitude': 17.4300, 'longitude': 78.4980}, // Intermediate corridor point
        {'latitude': 17.4250, 'longitude': 78.4950},
        {'latitude': 17.4100, 'longitude': 78.4850},
        {'latitude': 17.3616, 'longitude': 78.4747}, // Charminar
      ],
      'components': {
        'crime_safety': 82.0,
        'blackspot_safety': 90.0,
        'lighting_safety': 80.0,
        'emergency_access': 88.0,
      },
      'contributions': {
        'crime_compliance_pts': 28.7,
        'blackspot_compliance_pts': 22.5,
        'exposure_compliance_pts': 16.0,
        'emergency_proximity_pts': 17.6,
      },
      'raw_features': {
        'avg_police_dist_km': 0.8,
        'police_within_1km_count': 12,
        'min_hospital_dist_km': 0.6,
        'transit_count_within_500m': 8,
        'arterial_length_km': 10.5,
        'traversed_zones': ['Zone_Central'],
        'blackspot_count': 0,
      },
      'steps': [
        {
          'step_index': 0,
          'instruction': 'Head towards destination on Secunderabad to Charminar Corridor',
          'maneuver_type': 'depart',
          'road_name': 'Station Road',
          'distance_meters': 1140.0,
          'duration_seconds': 120.0,
          'latitude': 17.4334,
          'longitude': 78.5015,
        },
        {
          'step_index': 1,
          'instruction': 'Turn slight left onto MG Road',
          'maneuver_type': 'turn',
          'modifier': 'slight left',
          'road_name': 'MG Road',
          'distance_meters': 2300.0,
          'duration_seconds': 240.0,
          'latitude': 17.4250,
          'longitude': 78.4950,
        },
        {
          'step_index': 2,
          'instruction': 'Arrive at Charminar',
          'maneuver_type': 'arrive',
          'road_name': 'Charminar',
          'distance_meters': 0.0,
          'duration_seconds': 0.0,
          'latitude': 17.3616,
          'longitude': 78.4747,
        },
      ],
    };

    final route = EnrichedRoute.fromJson(routeJson);
    final journeyProv = JourneyProvider(apiService: ApiService());

    await journeyProv.startJourney(
      route: route,
      origin: {'address': 'Secunderabad'},
      destination: {'address': 'Charminar'},
    );

    // Initial maneuver distance must be realistic, strictly positive, and < total route distance
    expect(journeyProv.distanceToNextManeuverMeters, greaterThan(0.0));
    expect(journeyProv.distanceToNextManeuverMeters, lessThan(route.distanceKm * 1000.0));
    expect(journeyProv.currentInstruction.contains('13545'), isFalse);
    expect(journeyProv.remainingDistanceKm, closeTo(12.0, 0.5));

    // Simulate off-route emulator GPS position in Mountain View, CA (37.4219983, -122.084)
    journeyProv.updateLocation(const LatLng(37.4219983, -122.084));
    expect(journeyProv.isOffRoute, isTrue);

    // Maneuver distance must remain grounded in Hyderabad corridor geometry (never 13545 km)
    expect(journeyProv.distanceToNextManeuverMeters, greaterThanOrEqualTo(0.0));
    expect(journeyProv.distanceToNextManeuverMeters, lessThan(route.distanceKm * 1000.0));
    expect(journeyProv.currentInstruction.contains('13545'), isFalse);
    expect(journeyProv.remainingDistanceKm, lessThanOrEqualTo(route.distanceKm + 0.1));

    // Simulate on-route location approaching maneuver 1
    journeyProv.updateLocation(const LatLng(17.4300, 78.4980));
    expect(journeyProv.isOffRoute, isFalse);
    expect(journeyProv.distanceToNextManeuverMeters, greaterThan(0.0));
    expect(journeyProv.distanceToNextManeuverMeters, lessThan(2000.0));
  });

  test('JourneyProvider updates live GPS coordinates and rotates bearing dynamically with walking displacement', () async {
    final routeJson = {
      'route_id': 'Route_Live_GPS_Test',
      'summary': 'Moosarambagh to Dilsukhnagar Main Road',
      'safety_score': 88.0,
      'safety_tier': 'High Safety Corridor',
      'is_recommended_safer': true,
      'is_fastest': true,
      'distance_km': 3.5,
      'duration_min': 8.0,
      'polyline_coords': [
        {'latitude': 17.3750, 'longitude': 78.5150},
        {'latitude': 17.3750, 'longitude': 78.5200},
        {'latitude': 17.3750, 'longitude': 78.5250},
      ],
      'components': {
        'S_police': 80.0,
        'S_medical': 75.0,
        'S_transit': 85.0,
        'S_arterial': 90.0,
        'P_crime': 10.0,
        'P_blackspot': 5.0,
        'P_exposure': 15.0,
      },
      'contributions': {
        'police_pts': 20.0,
        'medical_pts': 15.0,
        'transit_pts': 12.0,
        'arterial_pts': 10.0,
        'crime_compliance_pts': 14.0,
        'blackspot_compliance_pts': 9.0,
        'exposure_compliance_pts': 8.5,
      },
      'raw_features': {
        'avg_police_dist_km': 1.1,
        'police_within_1km_count': 3,
        'min_hospital_dist_km': 0.8,
        'transit_count_within_500m': 5,
        'arterial_length_km': 3.5,
        'traversed_zones': ['East Zone'],
        'blackspot_count': 0,
      },
      'steps': [
        {
          'step_index': 0,
          'instruction': 'Head east on Moosarambagh Main Road',
          'maneuver_type': 'depart',
          'road_name': 'Moosarambagh Road',
          'distance_meters': 500.0,
          'duration_seconds': 60.0,
          'latitude': 17.3750,
          'longitude': 78.5150,
        },
      ],
    };

    final route = EnrichedRoute.fromJson(routeJson);
    final journeyProv = JourneyProvider(apiService: ApiService());

    await journeyProv.startJourney(
      route: route,
      origin: {'address': 'Ward 25, Moosarambagh', 'lat': 17.3750, 'lon': 78.5150},
      destination: {'address': 'Dilsukhnagar', 'lat': 17.3750, 'lon': 78.5250},
    );

    expect(journeyProv.currentLocation, isNotNull);
    expect(journeyProv.isNavigating, isTrue);

    // 1. Simulate walking 5 meters East (latitude same, longitude increases)
    final posEast = Position(
      latitude: 17.3750,
      longitude: 78.51505, // ~5.3 meters eastward
      timestamp: DateTime.now(),
      accuracy: 3.0,
      altitude: 500.0,
      altitudeAccuracy: 1.0,
      heading: 0.0, // Device has no hardware compass bearing
      headingAccuracy: 0.0,
      speed: 0.8, // Normal slow walking speed
      speedAccuracy: 0.1,
    );

    journeyProv.handlePositionUpdate(posEast);

    // Bearing must have rotated eastward (close to 90 degrees)
    expect(journeyProv.currentBearing, closeTo(90.0, 5.0));
    expect(journeyProv.currentLocation!.latitude, 17.3750);
    expect(journeyProv.currentLocation!.longitude, 78.51505);

    // 2. Simulate stopping / standing stationary: same position
    final posStationary = Position(
      latitude: 17.3750,
      longitude: 78.51505,
      timestamp: DateTime.now().add(const Duration(seconds: 1)),
      accuracy: 3.0,
      altitude: 500.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    journeyProv.handlePositionUpdate(posStationary);

    // Stationary phone must preserve previous valid bearing, not reset to 0
    expect(journeyProv.currentBearing, closeTo(90.0, 5.0));

    // 3. Simulate hardware compass / vehicle heading update (heading = 180 degrees South)
    final posSouthHeading = Position(
      latitude: 17.3749,
      longitude: 78.51505,
      timestamp: DateTime.now().add(const Duration(seconds: 2)),
      accuracy: 3.0,
      altitude: 500.0,
      altitudeAccuracy: 1.0,
      heading: 180.0,
      headingAccuracy: 5.0,
      speed: 1.2,
      speedAccuracy: 0.1,
    );

    journeyProv.handlePositionUpdate(posSouthHeading);
    expect(journeyProv.currentBearing, 180.0);
  });

  testWidgets('ActiveJourneyScreen displays clean navigation header hierarchy with active status, road name, and turn HUD', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final routeJson = {
      'route_id': 'Route_HUD_Header_Test',
      'summary': 'Raj Bhavan Road Safer Arterial Corridor',
      'safety_score': 91.5,
      'safety_tier': 'High Safety Corridor',
      'is_recommended_safer': true,
      'is_fastest': false,
      'distance_km': 7.2,
      'duration_min': 15.0,
      'polyline_coords': [
        {'latitude': 17.4150, 'longitude': 78.4600},
        {'latitude': 17.4200, 'longitude': 78.4650},
      ],
      'components': {
        'S_police': 80.0,
        'S_medical': 75.0,
        'S_transit': 85.0,
        'S_arterial': 90.0,
        'P_crime': 10.0,
        'P_blackspot': 5.0,
        'P_exposure': 15.0,
      },
      'contributions': {
        'police_pts': 20.0,
        'medical_pts': 15.0,
        'transit_pts': 12.0,
        'arterial_pts': 10.0,
        'crime_compliance_pts': 14.0,
        'blackspot_compliance_pts': 9.0,
        'exposure_compliance_pts': 8.5,
      },
      'raw_features': {
        'avg_police_dist_km': 1.1,
        'police_within_1km_count': 3,
        'min_hospital_dist_km': 0.8,
        'transit_count_within_500m': 5,
        'arterial_length_km': 7.2,
        'traversed_zones': ['Central Zone'],
        'blackspot_count': 0,
      },
      'steps': [
        {
          'step_index': 0,
          'instruction': 'Turn left onto Raj Bhavan Road',
          'maneuver_type': 'turn',
          'modifier': 'left',
          'road_name': 'Raj Bhavan Road',
          'distance_meters': 250.0,
          'duration_seconds': 40.0,
          'latitude': 17.4150,
          'longitude': 78.4600,
        },
        {
          'step_index': 1,
          'instruction': 'Continue straight past Somajiguda Circle',
          'maneuver_type': 'continue',
          'road_name': 'Somajiguda Main Road',
          'distance_meters': 1200.0,
          'duration_seconds': 120.0,
          'latitude': 17.4200,
          'longitude': 78.4650,
        },
      ],
    };

    final route = EnrichedRoute.fromJson(routeJson);
    final journeyProv = JourneyProvider(apiService: ApiService());

    await journeyProv.startJourney(
      route: route,
      origin: {'address': 'Khairatabad'},
      destination: {'address': 'Begumpet'},
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: journeyProv),
        ],
        child: const MaterialApp(
          home: ActiveJourneyScreen(),
        ),
      ),
    );

    await tester.pump();

    // 1. Verify "Navigation in progress" title is present
    expect(find.text('Navigation in progress'), findsOneWidget);

    // 2. Verify compact "Active" indicator is present
    expect(find.text('Active'), findsOneWidget);

    // 3. Verify actual corridor/road name appears on secondary line
    expect(find.text('Raj Bhavan Road Safer Arterial Corridor'), findsOneWidget);

    // 4. Verify turn-by-turn instruction and preview are displayed
    expect(find.textContaining('Turn left onto Raj Bhavan Road'), findsOneWidget);
    expect(find.text('Then: Continue straight past Somajiguda Circle'), findsOneWidget);

    // 5. Verify metrics and action controls
    expect(find.text('ESTIMATED TIME'), findsOneWidget);
    expect(find.text('DISTANCE REMAINING'), findsOneWidget);
    expect(find.text('END JOURNEY'), findsOneWidget);

    // 6. Verify old cluttered sentence 'Active Navigation • ' is completely removed
    expect(find.textContaining('Active Navigation •'), findsNothing);
  });

  group('Persistent Authentication Tests', () {
    test('AuthProvider.initializeAuth restores session when user is authenticated with backend', () async {
      final mockApi = _MockPersistentApiService(shouldSucceed: true);
      final authProv = AuthProvider(
        apiService: mockApi,
        firebaseTokenResolver: () async => 'mock_firebase_id_token_123',
      );

      expect(authProv.isAuthenticated, isFalse);
      expect(authProv.isInitialized, isFalse);

      final success = await authProv.initializeAuth();

      expect(success, isTrue);
      expect(authProv.isAuthenticated, isTrue);
      expect(authProv.isInitialized, isTrue);
      expect(authProv.user?.email, 'persisted_user@safeher.ai');
      expect(mockApi.authToken, 'mock_restored_jwt_token');
    });

    test('AuthProvider.initializeAuth handles backend restoration failure safely without claiming authenticated session', () async {
      final mockApi = _MockPersistentApiService(shouldSucceed: false);
      final authProv = AuthProvider(
        apiService: mockApi,
        firebaseTokenResolver: () async => 'mock_firebase_id_token_123',
      );

      final success = await authProv.initializeAuth();

      expect(success, isFalse);
      expect(authProv.isAuthenticated, isFalse);
      expect(authProv.isInitialized, isTrue);
      expect(authProv.user, isNull);
      expect(authProv.errorMessage, isNotNull);
      expect(authProv.errorMessage, contains('Could not restore previous session'));
      expect(mockApi.authToken, isNull);
    });

    test('AuthProvider.logout clears session and resets auth state', () async {
      final mockApi = _MockPersistentApiService(shouldSucceed: true);
      final authProv = AuthProvider(
        apiService: mockApi,
        firebaseTokenResolver: () async => 'mock_firebase_id_token_123',
      );

      await authProv.initializeAuth();
      expect(authProv.isAuthenticated, isTrue);

      await authProv.logout();

      expect(authProv.isAuthenticated, isFalse);
      expect(authProv.user, isNull);
      expect(mockApi.authToken, isNull);
    });

    testWidgets('SplashScreen routes to LoginScreen when unauthenticated startup occurs', (WidgetTester tester) async {
      final mockApi = _MockPersistentApiService(shouldSucceed: false);
      final authProv = AuthProvider(
        apiService: mockApi,
        firebaseTokenResolver: () async => null,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProv),
          ],
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify splash screen branding is shown initially
      expect(find.text('SafeHer AI'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance past the 1600ms branding delay
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pump(const Duration(milliseconds: 200));

      // Must have routed to LoginScreen
      expect(find.text('Welcome to SafeHer AI'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });

  group('P5 Offline Local Journey Persistence (LocalJourneyStore)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('LocalJourneyStore saves and loads journeys for a user', () async {
      final store = LocalJourneyStore(userId: 'test_user_01');
      final j1 = ActiveJourney.fromJson({
        'journey_id': 'JRN-LOCAL-01',
        'user_id': 'test_user_01',
        'origin': {'address': 'Madhapur'},
        'destination': {'address': 'Hitec City'},
        'route_summary': 'Cyber Towers Corridor',
        'distance_km': 3.5,
        'duration_min': 8.0,
        'safety_score': 90.0,
        'safety_tier': 'High Safety Corridor',
        'start_time': '2026-10-10T10:00:00Z',
        'status': 'completed',
      });

      await store.saveJourney(j1);
      final loaded = await store.loadJourneys();
      expect(loaded.length, 1);
      expect(loaded.first.journeyId, 'JRN-LOCAL-01');
      expect(loaded.first.routeSummary, 'Cyber Towers Corridor');
    });

    test('LocalJourneyStore isolates journeys by user ID', () async {
      final storeA = LocalJourneyStore(userId: 'user_a');
      final storeB = LocalJourneyStore(userId: 'user_b');

      final jA = ActiveJourney.fromJson({
        'journey_id': 'JRN-A',
        'user_id': 'user_a',
        'origin': {'address': 'A'},
        'destination': {'address': 'B'},
        'route_summary': 'Route A',
        'distance_km': 1.0,
        'duration_min': 5.0,
        'safety_score': 80.0,
        'safety_tier': 'Standard',
        'start_time': '2026-10-10T10:00:00Z',
        'status': 'completed',
      });

      await storeA.saveJourney(jA);
      expect((await storeA.loadJourneys()).length, 1);
      expect((await storeB.loadJourneys()).length, 0);
    });

    test('LocalJourneyStore delete and clear operations succeed', () async {
      final store = LocalJourneyStore(userId: 'test_user_del');
      final j1 = ActiveJourney.fromJson({
        'journey_id': 'JRN-DEL-1',
        'user_id': 'test_user_del',
        'origin': {'address': 'O'},
        'destination': {'address': 'D'},
        'route_summary': 'Corridor',
        'distance_km': 2.0,
        'duration_min': 5.0,
        'safety_score': 80.0,
        'safety_tier': 'Standard',
        'start_time': '2026-10-10T10:00:00Z',
        'status': 'completed',
      });

      await store.saveJourney(j1);
      expect((await store.loadJourneys()).length, 1);

      await store.deleteJourney('JRN-DEL-1');
      expect((await store.loadJourneys()).isEmpty, isTrue);
    });
  });

  group('P6 Google Sign-In and LoginScreen UI', () {
    testWidgets('LoginScreen renders Sign In with Google button', (WidgetTester tester) async {
      final authProv = AuthProvider(
        apiService: ApiService(),
        firebaseTokenResolver: () async => null,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProv),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Sign In with Google'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue as Guest / Demo Mode'), findsOneWidget);
    });
  });

  group('P2 Location Entry UI', () {
    testWidgets('RoutePlanningScreen provides Pick on map buttons for origin and destination', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RouteProvider>(create: (_) => RouteProvider(apiService: ApiService())),
            ChangeNotifierProvider<JourneyProvider>(create: (_) => JourneyProvider(apiService: ApiService())),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                apiService: ApiService(),
                firebaseTokenResolver: () async => null,
              ),
            ),
          ],
          child: const MaterialApp(
            home: RoutePlanningScreen(),
          ),
        ),
      );

      // Verify Pick on map buttons exist
      expect(find.text('Pick on map'), findsNWidgets(2));
    });
  });
}


class _MockPersistentApiService extends ApiService {
  final bool shouldSucceed;

  _MockPersistentApiService({
    this.shouldSucceed = true,
  });


  @override
  Future<AuthResult> authenticateFirebase(String idToken) async {
    if (!shouldSucceed) {
      throw Exception('Backend network connection timed out');
    }
    authToken = 'mock_restored_jwt_token';
    return AuthResult(
      accessToken: 'mock_restored_jwt_token',
      tokenType: 'bearer',
      user: UserProfile(
        id: 'user_restored_123',
        email: 'persisted_user@safeher.ai',
        fullName: 'Restored SafeHer User',
        phone: '+919876543210',
        createdAt: '2026-10-10T12:00:00Z',
      ),
    );
  }
}

