import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Privacy Matters',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'How SafeHer AI protects and uses your data',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),

                    _buildPrivacySection(
                      icon: Icons.location_on_outlined,
                      title: 'Location Information',
                      content:
                          'SafeHer AI uses your device location exclusively for route planning, comparing route safety levels, and navigating along selected corridors in Hyderabad. Your location is also shared with trusted contacts and nearest emergency services when you explicitly activate SOS.',
                    ),

                    _buildPrivacySection(
                      icon: Icons.analytics_outlined,
                      title: 'Safety Datasets & Route Calculation',
                      content:
                          'Route safety scores are computed against verified open spatial datasets of Hyderabad (police station locations, emergency hospitals, public transit stops, accident black spots) and jurisdictional crime review summaries. Routes are evaluated to assist your travel decisions.',
                    ),

                    _buildPrivacySection(
                      icon: Icons.history,
                      title: 'Journey History & Telemetry',
                      content:
                          'When you complete a journey, route metadata (start point, destination, distance, duration, and safety score) is recorded in Cloud Firestore and the SafeHer AI backend to populate your Journey History.',
                    ),

                    _buildPrivacySection(
                      icon: Icons.feedback_outlined,
                      title: 'User Feedback',
                      content:
                          'Feedback submitted after a journey (comfort level, perceived safety, noticed road issues) is logged anonymously for safety quality assessment and future periodic safety model evaluation.',
                    ),

                    _buildPrivacySection(
                      icon: Icons.warning_amber_outlined,
                      title: 'Emergency SOS Records',
                      content:
                          'When the SOS button is triggered, emergency telemetry (GPS coordinates, timestamp, and device battery level) is logged to identify the closest police station and notify registered trusted contacts.',
                    ),

                    _buildPrivacySection(
                      icon: Icons.lock_outline,
                      title: 'Authentication & Account Security',
                      content:
                          'User accounts and authentication are handled securely through Google Firebase Authentication. Passwords are encrypted by Firebase and are never stored in plaintext or exposed to anyone.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
