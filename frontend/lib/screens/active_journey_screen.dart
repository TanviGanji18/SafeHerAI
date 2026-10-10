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
  bool _arrivalDialogShown = false;

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
    if (_arrivalDialogShown) return;
    _arrivalDialogShown = true;

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

    // Auto-trigger arrival dialog if reached during live navigation
    if (journeyProv.isDestinationReached && !_arrivalDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleArrivalOrEnd(context);
      });
    }

    final route = journey.selectedRoute;
    final initialCam = CameraPosition(
      target: journeyProv.currentLocation ?? const LatLng(AppConstants.hyderabadCenterLat, AppConstants.hyderabadCenterLon),
      zoom: 16.0,
    );

    final currentManeuver = journeyProv.currentStep;
    final nextManeuver = journeyProv.nextStep;

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
                  initialCenter: journeyProv.currentLocation ??
                      const LatLng(AppConstants.hyderabadCenterLat, AppConstants.hyderabadCenterLon),
                  polylines: _buildPolylines(journeyProv),
                  markers: _buildMarkers(journeyProv),
                  activePolylinePoints: route.polylineCoords,
                  userLocation: journeyProv.currentLocation != null
                      ? CoordinatePoint(
                          latitude: journeyProv.currentLocation!.latitude,
                          longitude: journeyProv.currentLocation!.longitude,
                        )
                      : null,
                  destinationLocation: journeyProv.destinationLocation != null
                      ? CoordinatePoint(
                          latitude: journeyProv.destinationLocation!.latitude,
                          longitude: journeyProv.destinationLocation!.longitude,
                        )
                      : null,
                  userBearing: journeyProv.currentBearing,
                  completedPolylineIndex: journeyProv.completedPolylineIndex,
                  isNavigating: journeyProv.isNavigating,
                  isCameraFollowing: journeyProv.isCameraFollowing,
                  onRecenter: () => journeyProv.setCameraFollowing(true),
                  onPanStart: () => journeyProv.setCameraFollowing(false),
                  corridorTitle: (route.summary.trim().isNotEmpty && route.summary != 'null')
                      ? route.summary
                      : 'Recommended Safer Corridor',
                ),

          // 2. Turn-By-Turn HUD Banner (Google Maps Navigation Style)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Navigation Maneuver Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F5132), // Emerald Navigation Green
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Compact "Active" status indicator + "Navigation in progress" title + Safety Badge
                        Row(
                          children: [
                            if (journeyProv.isNavigating && !journeyProv.isDestinationReached) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF25D366), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF25D366),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Expanded(
                              child: Text(
                                'Navigation in progress',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SafetyBadge(
                              score: route.safetyScore,
                              tier: route.safetyTier,
                              isCompact: true,
                            ),
                          ],
                        ),

                        // Row 2: Secondary line with actual road or route name
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.alt_route_rounded, size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (route.summary.trim().isNotEmpty && route.summary != 'null')
                                      ? route.summary
                                      : 'Recommended Safer Corridor',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 10),

                        // Row 3: Next turn maneuver icon + instruction + preview
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                currentManeuver?.icon ?? Icons.navigation_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    journeyProv.currentInstruction,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (nextManeuver != null) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          nextManeuver.icon,
                                          color: Colors.white70,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Then: ${nextManeuver.instruction}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Off-Route Warning Banner with Recalculation
                  if (journeyProv.isOffRoute)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wrong_location_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Off route detected',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          journeyProv.isRecalculating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : InkWell(
                                  onTap: () => journeyProv.recalculateRoute(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'RECALCULATE',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
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
                          BoxShadow(
                            color: AppColors.emergencyRed.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emergency, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'SOS ACTIVE • GPS Shared With Police & Contacts',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _callHelpline('100'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DIAL 100',
                                style: TextStyle(
                                  color: AppColors.emergencyRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Recenter Floating Indicator (if camera was manually panned)
          if (!journeyProv.isCameraFollowing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 195,
              child: Center(
                child: InkWell(
                  onTap: () => journeyProv.setCameraFollowing(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Re-center Camera',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 4. Floating Persistent SOS Button
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
              label: const Text(
                'SOS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // 5. Quick Simulator Button (Advances coordinate along route for emulator tests)
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

          // 6. Bottom Navigation Card
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
                            const Text(
                              'ESTIMATED TIME',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${journeyProv.remainingDurationMin.toStringAsFixed(0)} mins',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'DISTANCE REMAINING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${journeyProv.remainingDistanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Actions Row: End Journey
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleArrivalOrEnd(context),
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: const Text(
                              'END JOURNEY',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
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
