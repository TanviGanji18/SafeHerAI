import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../models/route_model.dart';
import '../providers/journey_provider.dart';
import '../widgets/safety_badge.dart';
import '../widgets/safeher_demo_map.dart';
import 'journey_report_screen.dart';

class ActiveJourneyScreen extends StatefulWidget {
  const ActiveJourneyScreen({Key? key}) : super(key: key);

  @override
  State<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends State<ActiveJourneyScreen> {
  // ignore: unused_field
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
  }

  Set<Polyline> _buildPolylines(JourneyProvider journeyProv) {
    final polylines = <Polyline>{};
    final route = journeyProv.activeJourney?.selectedRoute;
    if (route == null) return polylines;

    final points = route.polylineCoords.map((c) => LatLng(c.latitude, c.longitude)).toList();
    Color polyColor = AppColors.safeGreen;
    if (route.isFastest && !route.isRecommendedSafer) {
      polyColor = Colors.blue.shade700;
    } else if (!route.isRecommendedSafer && !route.isFastest) {
      polyColor = Colors.indigo.shade600;
    }

    polylines.add(
      Polyline(
        polylineId: PolylineId(route.routeId),
        points: points,
        color: polyColor,
        width: 6,
        zIndex: 2,
      ),
    );
    return polylines;
  }

  Set<Marker> _buildMarkers(JourneyProvider journeyProv) {
    final markers = <Marker>{};

    // User's Current Location Marker
    if (journeyProv.currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_user_location'),
          position: journeyProv.currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: const InfoWindow(title: 'You are here', snippet: 'Navigating along safer corridor'),
          zIndex: 5,
        ),
      );
    }

    // Destination Marker
    if (journeyProv.destinationLocation != null) {
      final destName = journeyProv.activeJourney?.destination['address'] ??
          journeyProv.activeJourney?.destination['name'] ??
          'Destination';
      markers.add(
        Marker(
          markerId: const MarkerId('journey_destination'),
          position: journeyProv.destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(title: 'Destination', snippet: destName),
          zIndex: 4,
        ),
      );
    }

    return markers;
  }

  void _showSOSConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 28),
            SizedBox(width: 8),
            Text('Confirm Emergency SOS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to activate SOS?\n\nThis will broadcast your live GPS coordinates to Telangana Police and notify your trusted emergency contacts.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleActivateSOS(context);
            },
            icon: const Icon(Icons.emergency, color: Colors.white),
            label: const Text('ACTIVATE SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleActivateSOS(BuildContext context) async {
    final journeyProv = Provider.of<JourneyProvider>(context, listen: false);
    await journeyProv.activateJourneySOS();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emergencyRed,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('🚨 SOS DISPATCHED: Police desk and emergency contacts notified!'),
              ),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleArrivalOrEnd(BuildContext context) {
    final journeyProv = Provider.of<JourneyProvider>(context, listen: false);
    journeyProv.triggerDestinationReached();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.safeGreen, size: 28),
            SizedBox(width: 8),
            Text('Destination Reached', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'You have arrived at your destination safely.\n\nWould you like to share your journey experience to help improve safety analysis for other women?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              journeyProv.skipFeedback();
              Navigator.of(context).pop(); // Back to Home
            },
            child: const Text('SKIP', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const JourneyReportScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('HOW WAS YOUR JOURNEY?', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _callHelpline(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeyProv = Provider.of<JourneyProvider>(context);
    final journey = journeyProv.activeJourney;

    if (journey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Journey')),
        body: const Center(child: Text('No active journey in progress.')),
      );
    }

    final route = journey.selectedRoute;
    final initialCam = CameraPosition(
      target: journeyProv.currentLocation ?? const LatLng(AppConstants.hyderabadCenterLat, AppConstants.hyderabadCenterLon),
      zoom: 14.5,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. Dominant Map: Live Google Maps (if API key configured) or SafeHer Demo Canvas
          AppConstants.isGoogleMapsConfigured
              ? GoogleMap(
                  initialCameraPosition: initialCam,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  polylines: _buildPolylines(journeyProv),
                  markers: _buildMarkers(journeyProv),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                )
              : SafeHerDemoMap(
                  initialCenter: journeyProv.currentLocation ?? const LatLng(AppConstants.hyderabadCenterLat, AppConstants.hyderabadCenterLon),
                  polylines: _buildPolylines(journeyProv),
                  markers: _buildMarkers(journeyProv),
                  activePolylinePoints: route.polylineCoords,
                  userLocation: journeyProv.currentLocation != null
                      ? CoordinatePoint(latitude: journeyProv.currentLocation!.latitude, longitude: journeyProv.currentLocation!.longitude)
                      : null,
                  destinationLocation: journeyProv.destinationLocation != null
                      ? CoordinatePoint(latitude: journeyProv.destinationLocation!.latitude, longitude: journeyProv.destinationLocation!.longitude)
                      : null,
                  corridorTitle: 'Active Navigation • ${route.summary}',
                ),

          // 2. Top Navigation HUD Banner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Navigation Guidance Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: route.isRecommendedSafer ? AppColors.safeGreen : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.navigation, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                journeyProv.currentInstruction,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'To: ${journey.destination['address'] ?? journey.destination['name'] ?? 'Destination'}',
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SafetyBadge(score: route.safetyScore, tier: route.safetyTier, isCompact: true),
                      ],
                    ),
                  ),

                  // Emergency SOS Active Banner (if SOS triggered)
                  if (journeyProv.emergencyActive)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: AppColors.emergencyRed.withOpacity(0.4), blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emergency, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'SOS ACTIVE • GPS Shared With Police & Contacts',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          InkWell(
                            onTap: () => _callHelpline('100'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                              child: const Text('DIAL 100', style: TextStyle(color: AppColors.emergencyRed, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Floating Persistent SOS Button (Accessible at all times)
          Positioned(
            left: 20,
            bottom: 180,
            child: FloatingActionButton.extended(
              heroTag: 'journey_sos_fab',
              onPressed: () => _showSOSConfirmationDialog(context),
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              elevation: 6,
              icon: const Icon(Icons.emergency, size: 22),
              label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0)),
            ),
          ),

          // 4. Quick Simulator Button (Advances coordinate along route for emulator demonstrations)
          Positioned(
            right: 20,
            bottom: 180,
            child: FloatingActionButton.small(
              heroTag: 'journey_advance_fab',
              tooltip: 'Simulate Step',
              onPressed: () => journeyProv.advanceAlongRoute(),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 4,
              child: const Icon(Icons.fast_forward, size: 20),
            ),
          ),

          // 5. Bottom Navigation Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('REMAINING TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              '${journeyProv.remainingDurationMin.toStringAsFixed(0)} mins',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('DISTANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              '${journeyProv.remainingDistanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Actions Row: End Journey / Reached
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleArrivalOrEnd(context),
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: const Text('END JOURNEY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.emergencyRed,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
