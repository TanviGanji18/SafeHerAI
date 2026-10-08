import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Navigation & Safety Preferences
  bool _preferSaferCorridor = true;
  bool _alertBlackSpots = true;
  bool _showNearbySafeSpotsOnMap = true;
  bool _journeyNotifications = true;
  bool _vibrateOnSOS = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Safety & Routing Preferences
            const Text(
              'Route & Safety Preferences',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Prioritize Safer Route Corridor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Pre-selects route with higher police density and arterial lighting', style: TextStyle(fontSize: 12)),
                    value: _preferSaferCorridor,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _preferSaferCorridor = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Accident Black-Spot Warnings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Highlights known high-collision junctions during route comparison', style: TextStyle(fontSize: 12)),
                    value: _alertBlackSpots,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _alertBlackSpots = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Display Safe Spots on Map', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Show police and emergency medical icons along active route', style: TextStyle(fontSize: 12)),
                    value: _showNearbySafeSpotsOnMap,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _showNearbySafeSpotsOnMap = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Emergency & Notifications
            const Text(
              'Emergency & Notifications',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Journey Arrival Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Prompt for route feedback upon reaching destination', style: TextStyle(fontSize: 12)),
                    value: _journeyNotifications,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _journeyNotifications = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Haptic Alert on SOS Activation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Vibrate device when countdown starts or SOS is broadcast', style: TextStyle(fontSize: 12)),
                    value: _vibrateOnSOS,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _vibrateOnSOS = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Map System Diagnostics
            const Text(
              'Map Engine & Data Source',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Navigation Engine',
                      AppConstants.isGoogleMapsConfigured ? 'Google Maps SDK' : 'SafeHer High-Contrast Canvas',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Spatial Jurisdiction', 'Greater Hyderabad (GHMC & Cyberabad)'),
                    const SizedBox(height: 10),
                    _buildInfoRow('Safety Scoring Algorithm', '7-Factor Multi-Criteria Evaluation'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
