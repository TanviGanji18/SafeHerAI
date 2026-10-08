import 'package:flutter/material.dart';

class AppConstants {
  // Backend API URL (Use 10.0.2.2 for Android Studio Emulator, localhost for Web/macOS/Windows)
  static const String defaultApiUrl = 'http://10.0.2.2:8000';
  static const String localApiUrl = 'http://localhost:8000';

  // Hyderabad City Reference Point
  static const double hyderabadCenterLat = 17.3850;
  static const double hyderabadCenterLon = 78.4867;

  // Emergency Helplines
  static const String telanganaPoliceNumber = '100';
  static const String nationalEmergencyNumber = '112';
  static const String sheTeamsNumber = '9490616555';
  static const String womenHelplineNumber = '181';

  // Google Maps SDK Configuration
  // Set to your valid Google Cloud Maps API key when billing and keys are ready.
  // When empty or starting with 'YOUR_', SafeHer AI automatically uses the
  // polished SafeHer Demo Navigation Canvas to prevent Android MapsInitializer crash.
  static const String googleMapsApiKey = '';

  static bool get isGoogleMapsConfigured =>
      googleMapsApiKey.trim().isNotEmpty &&
      !googleMapsApiKey.startsWith('YOUR_') &&
      !googleMapsApiKey.contains('placeholder');
}

class AppColors {
  // Brand Palette
  static const Color primary = Color(0xFF6B21A8); // Deep Safety Purple
  static const Color primaryLight = Color(0xFF9333EA);
  static const Color primaryDark = Color(0xFF4A154B);
  static const Color accent = Color(0xFFE11D48); // High-alert rose
  static const Color emergencyRed = Color(0xFFDC2626); // SOS Crimson
  static const Color safeGreen = Color(0xFF059669); // Safer route green
  static const Color warningAmber = Color(0xFFD97706); // Moderate warning amber
  static const Color cautionRed = Color(0xFFEF4444); // Caution red

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}
