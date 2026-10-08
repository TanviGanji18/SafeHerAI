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
import 'package:safeher_ai/models/journey_model.dart';

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
    expect(find.textContaining('Emergency Phone:'), findsOneWidget);
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
}
