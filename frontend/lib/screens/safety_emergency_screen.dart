import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import 'nearby_amenities_screen.dart';
import 'sos_screen.dart';

class SafetyEmergencyScreen extends StatelessWidget {
  const SafetyEmergencyScreen({Key? key}) : super(key: key);

  void _callPhone(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety & Emergency'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Disclaimer Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'SafeHer AI does not automatically dispatch police without confirmation. In an urgent situation, tap to call the official Telangana helplines or activate Emergency SOS below.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Emergency Helplines
            const Text(
              'Official Emergency Helplines',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            _buildEmergencyCard(
              title: 'Police',
              number: '100',
              subtitle: 'Telangana Police 24/7 Emergency Dispatch',
              icon: Icons.local_police,
              iconColor: Colors.blue.shade700,
              onCall: () => _callPhone('100'),
            ),

            _buildEmergencyCard(
              title: 'Emergency',
              number: '112',
              subtitle: 'National Unified Emergency Response System',
              icon: Icons.emergency,
              iconColor: AppColors.emergencyRed,
              onCall: () => _callPhone('112'),
            ),

            _buildEmergencyCard(
              title: 'Women Helpline',
              number: '181',
              subtitle: '24/7 National Women Distress Helpline',
              icon: Icons.support_agent,
              iconColor: Colors.purple.shade700,
              onCall: () => _callPhone('181'),
            ),

            _buildEmergencyCard(
              title: 'Hyderabad SHE Teams',
              number: '9490616555',
              subtitle: 'Telangana Women Safety & Rapid Assistance Wing',
              icon: Icons.security,
              iconColor: AppColors.safeGreen,
              onCall: () => _callPhone('9490616555'),
            ),

            const SizedBox(height: 20),

            // Civic Safe Spots Navigation Links
            const Text(
              'Nearby Emergency Infrastructure',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(Icons.local_police_outlined, color: Colors.blue),
                    ),
                    title: const Text('Nearby Police Stations', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Locate closest law enforcement stations along your route'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NearbyAmenitiesScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEE2E2),
                      child: Icon(Icons.local_hospital_outlined, color: AppColors.emergencyRed),
                    ),
                    title: const Text('Nearby Hospitals', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Locate 24/7 emergency care and trauma centers'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NearbyAmenitiesScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Emergency SOS Trigger Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SOSScreen()),
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 22),
                label: const Text('Open Emergency SOS Dispatch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard({
    required String title,
    required String number,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onCall,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            number,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: iconColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: onCall,
              icon: const Icon(Icons.call, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.safeGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
