import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';
import '../providers/route_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/journey_provider.dart';
import '../widgets/safety_badge.dart';
import '../widgets/sos_button.dart';
import '../widgets/safeher_demo_map.dart';
import 'route_planning_screen.dart';
import 'route_comparison_screen.dart';
import 'safety_breakdown_screen.dart';
import 'active_journey_screen.dart';
import 'sos_screen.dart';
import 'nearby_amenities_screen.dart';
import 'trusted_contacts_screen.dart';
import 'profile_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({Key? key}) : super(key: key);

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  GoogleMapController? _mapController;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(AppConstants.hyderabadCenterLat, AppConstants.hyderabadCenterLon),
    zoom: 12.8,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routeProv = Provider.of<RouteProvider>(context, listen: false);
      routeProv.fetchNearbyAmenities(AppConstants.hyderabadCenterLat, AppConstants.hyderabadCenterLon);
    });
  }

  Set<Polyline> _buildPolylines(RouteProvider routeProv) {
    final polylines = <Polyline>{};
    if (routeProv.planResult == null) return polylines;

    for (final route in routeProv.planResult!.routes) {
      final isSelected = route.routeId == routeProv.selectedRoute?.routeId;
      final points = route.polylineCoords.map((c) => LatLng(c.latitude, c.longitude)).toList();

      Color polyColor;
      if (route.isRecommendedSafer) {
        polyColor = isSelected ? AppColors.safeGreen : AppColors.safeGreen.withOpacity(0.5);
      } else if (route.isFastest) {
        polyColor = isSelected ? Colors.blue.shade700 : Colors.blue.shade300;
      } else {
        polyColor = isSelected ? Colors.orange.shade800 : Colors.orange.shade300;
      }

      polylines.add(
        Polyline(
          polylineId: PolylineId(route.routeId),
          points: points,
          color: polyColor,
          width: isSelected ? 6 : 4,
          zIndex: isSelected ? 2 : 1,
          consumeTapEvents: true,
          onTap: () {
            routeProv.selectRoute(route);
          },
        ),
      );
    }

    return polylines;
  }

  Set<Marker> _buildMarkers(RouteProvider routeProv) {
    final markers = <Marker>{};

    // 1. Origin and Destination Markers
    if (routeProv.planResult != null) {
      final orig = routeProv.planResult!.origin;
      final dest = routeProv.planResult!.destination;

      markers.add(
        Marker(
          markerId: const MarkerId('origin_marker'),
          position: LatLng(orig.latitude, orig.longitude),
          infoWindow: InfoWindow(title: 'Origin', snippet: routeProv.planResult!.originName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId('dest_marker'),
          position: LatLng(dest.latitude, dest.longitude),
          infoWindow: InfoWindow(title: 'Destination', snippet: routeProv.planResult!.destinationName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
      );
    }

    // 2. Safe Spot Amenities Markers
    final safeSpots = routeProv.nearbySafeSpots;
    if (safeSpots != null) {
      if (routeProv.showPolice) {
        for (final ps in safeSpots.policeStations) {
          markers.add(
            Marker(
              markerId: MarkerId(ps.id),
              position: LatLng(ps.latitude, ps.longitude),
              infoWindow: InfoWindow(title: ps.name, snippet: 'Police Station • ${ps.distanceKm} km away'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
          );
        }
      }

      if (routeProv.showHospitals) {
        for (final h in safeSpots.hospitals) {
          markers.add(
            Marker(
              markerId: MarkerId(h.id),
              position: LatLng(h.latitude, h.longitude),
              infoWindow: InfoWindow(title: h.name, snippet: 'Hospital • ${h.distanceKm} km away'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
      }

      if (routeProv.showTransit) {
        for (final t in safeSpots.transitStations) {
          markers.add(
            Marker(
              markerId: MarkerId(t.id),
              position: LatLng(t.latitude, t.longitude),
              infoWindow: InfoWindow(title: t.name, snippet: '${t.category} • ${t.distanceKm} km away'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ),
          );
        }
      }

      if (routeProv.showBlackspots) {
        for (final bs in safeSpots.accidentBlackspots) {
          markers.add(
            Marker(
              markerId: MarkerId(bs.id),
              position: LatLng(bs.latitude, bs.longitude),
              infoWindow: InfoWindow(title: bs.name, snippet: 'Traffic Black Spot Alert'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            ),
          );
        }
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final routeProv = Provider.of<RouteProvider>(context);
    final selected = routeProv.selectedRoute;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Navigation Map: Live Google Maps (if API key configured) or SafeHer Demo Canvas
          AppConstants.isGoogleMapsConfigured
              ? GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  polylines: _buildPolylines(routeProv),
                  markers: _buildMarkers(routeProv),
                  onMapCreated: (controller) => _mapController = controller,
                )
              : SafeHerDemoMap(
                  initialCenter: const LatLng(AppConstants.hyderabadCenterLat, AppConstants.hyderabadCenterLon),
                  polylines: _buildPolylines(routeProv),
                  markers: _buildMarkers(routeProv),
                  activePolylinePoints: selected?.polylineCoords,
                  safeSpots: routeProv.nearbySafeSpots,
                  showPolice: routeProv.showPolice,
                  showHospitals: routeProv.showHospitals,
                  showTransit: routeProv.showTransit,
                  showBlackspots: routeProv.showBlackspots,
                  corridorTitle: selected != null ? selected.summary : null,
                ),

          // 2. Top Header & Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Bar Card & Top-Right Profile Avatar Button
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RoutePlanningScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      routeProv.planResult != null
                                          ? '${routeProv.planResult!.destinationName ?? "Destination"}'
                                          : 'Where to? (e.g. Hitec City, Charminar)',
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (routeProv.planResult != null)
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: routeProv.clearRoutes,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profile Avatar Button
                      Material(
                        elevation: 4,
                        shape: const CircleBorder(),
                        color: Colors.white,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                            ),
                            child: Center(
                              child: Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  final name = auth.user?.fullName ?? '';
                                  final initials = name.trim().isNotEmpty
                                      ? name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase()
                                      : '👤';
                                  return Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Map Layer Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Police'),
                          avatar: const Icon(Icons.local_police, size: 16, color: Colors.blue),
                          selected: routeProv.showPolice,
                          onSelected: (_) => routeProv.togglePolice(),
                          backgroundColor: Colors.white,
                          selectedColor: Colors.blue.shade100,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Hospitals'),
                          avatar: const Icon(Icons.local_hospital, size: 16, color: Colors.red),
                          selected: routeProv.showHospitals,
                          onSelected: (_) => routeProv.toggleHospitals(),
                          backgroundColor: Colors.white,
                          selectedColor: Colors.red.shade100,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Transit'),
                          avatar: const Icon(Icons.directions_subway, size: 16, color: Colors.orange),
                          selected: routeProv.showTransit,
                          onSelected: (_) => routeProv.toggleTransit(),
                          backgroundColor: Colors.white,
                          selectedColor: Colors.orange.shade100,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Black Spots'),
                          avatar: const Icon(Icons.warning, size: 16, color: Colors.purple),
                          selected: routeProv.showBlackspots,
                          onSelected: (_) => routeProv.toggleBlackspots(),
                          backgroundColor: Colors.white,
                          selectedColor: Colors.purple.shade100,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Quick Action Buttons (Safe Spots, Center Map)
          Positioned(
            right: 16,
            bottom: selected != null ? 245 : 96,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'btn_safe_spots',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NearbyAmenitiesScreen()),
                    );
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  child: const Icon(Icons.shield_outlined),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'btn_contacts',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TrustedContactsScreen()),
                    );
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  child: const Icon(Icons.people_outline),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'btn_recenter',
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(_initialCameraPosition),
                    );
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // 4. Bottom Selected Route Card (if routes active)
          if (selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (selected.isRecommendedSafer)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.safeGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('🛡️ SAFER ROUTE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          else if (selected.isFastest)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('⚡ FASTEST ROUTE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('ALTERNATIVE ROUTE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          const Spacer(),
                          SafetyBadge(score: selected.safetyScore, tier: selected.safetyTier, isCompact: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selected.summary,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${selected.durationMin.toStringAsFixed(0)} min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(' · ${selected.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SafetyBreakdownScreen(route: selected),
                                ),
                              );
                            },
                            child: const Text(
                              'Why this route? →',
                              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RouteComparisonScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            child: const Text('All Routes'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final journeyProv = Provider.of<JourneyProvider>(context, listen: false);
                                final authProv = Provider.of<AuthProvider>(context, listen: false);
                                final plan = routeProv.planResult;
                                if (plan != null) {
                                  final userId = authProv.user?.uid ?? 'guest_user';
                                  await journeyProv.startJourney(
                                    userId: userId,
                                    originName: plan.originName,
                                    destName: plan.destinationName,
                                    originCoords: {'lat': plan.origin.latitude, 'lon': plan.origin.longitude},
                                    destCoords: {'lat': plan.destination.latitude, 'lon': plan.destination.longitude},
                                    selectedRoute: selected,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.navigation, size: 18),
                              label: const Text(
                                'START JOURNEY',
                                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
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

          // 5. High-Visibility SOS Floating Trigger Button (Available on Map)
          Positioned(
            left: 16,
            bottom: selected != null ? 245 : 24,
            child: FloatingSOSButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SOSScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
