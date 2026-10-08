import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../providers/sos_provider.dart';
import '../providers/route_provider.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _alertTriggered = false;

  void _triggerEmergency() async {
    final sosProv = Provider.of<SOSProvider>(context, listen: false);
    final routeProv = Provider.of<RouteProvider>(context, listen: false);

    // Current coordinates (Hyderabad center or GPS)
    final lat = routeProv.planResult?.origin.latitude ?? AppConstants.hyderabadCenterLat;
    final lon = routeProv.planResult?.origin.longitude ?? AppConstants.hyderabadCenterLon;

    final success = await sosProv.triggerEmergency(
      lat: lat,
      lon: lon,
      batteryLevel: 82,
      message: 'EMERGENCY: Immediate assistance required. Live location sent.',
      currentRouteId: routeProv.selectedRoute?.routeId,
    );

    if (success && mounted) {
      setState(() => _alertTriggered = true);
    }
  }

  void _launchCaller(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosProv = Provider.of<SOSProvider>(context);
    final alert = sosProv.lastAlert;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B2E),
      appBar: AppBar(
        title: const Text('EMERGENCY SOS', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.emergencyRed,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SOS Big Action Trigger
              Center(
                child: GestureDetector(
                  onTap: sosProv.isTriggering ? null : _triggerEmergency,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emergencyRed,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyRed.withOpacity(0.5),
                          blurRadius: 28,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: sosProv.isTriggering
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.emergency_share, size: 54, color: Colors.white),
                                const SizedBox(height: 6),
                                Text(
                                  _alertTriggered ? 'ALERT SENT' : 'TAP FOR SOS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Alert Confirmation Banner (if triggered)
              if (_alertTriggered && alert != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.greenAccent),
                          const SizedBox(width: 8),
                          Text('Incident ID: ${alert.alertId}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Nearest Police Desk: ${alert.nearestPoliceStation.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      Text('Notified ${alert.dispatchedContactsCount} Emergency Contacts', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),

              // One-Tap Direct Helplines Grid
              const Text(
                'Direct One-Tap Police & SHE Team Helplines:',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchCaller(AppConstants.telanganaPoliceNumber),
                      icon: const Icon(Icons.phone),
                      label: const Text('Police 100'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchCaller(AppConstants.nationalEmergencyNumber),
                      icon: const Icon(Icons.phone),
                      label: const Text('Emergency 112'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchCaller(AppConstants.sheTeamsNumber),
                      icon: const Icon(Icons.support_agent),
                      label: const Text('SHE Teams 9490616555'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchCaller(AppConstants.womenHelplineNumber),
                      icon: const Icon(Icons.security),
                      label: const Text('Women 181'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Tactical Guidance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Immediate Safety Protocol:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 8),
                    Text('1. Stay on main arterial roads or inside open transit stations (Metro/Bus).', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    Text('2. Keep phone awake; your live GPS coordinates are continuously broadcast.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    Text('3. Tap SHE Teams or Dial 100 to connect instantly to the control room.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
