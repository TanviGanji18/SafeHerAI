import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;

import '../constants/app_constants.dart';
import '../models/route_model.dart';
import '../models/amenity_model.dart';

/// Interactive map used by SafeHer AI.
/// Uses OpenStreetMap tiles through flutter_map.
/// Supports turn-by-turn navigation arrow/puck, camera follow, and polyline progress.
class SafeHerDemoMap extends StatefulWidget {
  final gmaps.LatLng initialCenter;
  final Set<gmaps.Polyline> polylines;
  final Set<gmaps.Marker> markers;
  final List<CoordinatePoint>? activePolylinePoints;
  final CoordinatePoint? userLocation;
  final CoordinatePoint? destinationLocation;
  final NearbySafeSpots? safeSpots;
  final bool showPolice;
  final bool showHospitals;
  final bool showTransit;
  final bool showBlackspots;
  final String? corridorTitle;

  // Turn-by-Turn Navigation Enhancements
  final double? userBearing;
  final int? completedPolylineIndex;
  final bool isNavigating;
  final bool isCameraFollowing;
  final VoidCallback? onRecenter;
  final VoidCallback? onPanStart;

  const SafeHerDemoMap({
    Key? key,
    this.initialCenter = const gmaps.LatLng(
      AppConstants.hyderabadCenterLat,
      AppConstants.hyderabadCenterLon,
    ),
    this.polylines = const {},
    this.markers = const {},
    this.activePolylinePoints,
    this.userLocation,
    this.destinationLocation,
    this.safeSpots,
    this.showPolice = true,
    this.showHospitals = true,
    this.showTransit = true,
    this.showBlackspots = true,
    this.corridorTitle,
    this.userBearing,
    this.completedPolylineIndex,
    this.isNavigating = false,
    this.isCameraFollowing = true,
    this.onRecenter,
    this.onPanStart,
  }) : super(key: key);

  @override
  State<SafeHerDemoMap> createState() => _SafeHerDemoMapState();
}

class _SafeHerDemoMapState extends State<SafeHerDemoMap> {
  final fmap.MapController _mapController = fmap.MapController();

  ll.LatLng _toLatLng(double latitude, double longitude) {
    return ll.LatLng(latitude, longitude);
  }

  @override
  void didUpdateWidget(SafeHerDemoMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 1. Initial GPS position lock: center map on user when location arrives
    if (oldWidget.userLocation == null && widget.userLocation != null) {
      _mapController.move(
        _toLatLng(widget.userLocation!.latitude, widget.userLocation!.longitude),
        widget.isNavigating ? 16.5 : 15.0,
      );
      return;
    }

    // 2. Camera follow user position during live navigation
    if (widget.isNavigating &&
        widget.isCameraFollowing &&
        widget.userLocation != null) {
      final oldLoc = oldWidget.userLocation;
      final newLoc = widget.userLocation!;
      if (oldLoc == null ||
          oldLoc.latitude != newLoc.latitude ||
          oldLoc.longitude != newLoc.longitude) {
        _mapController.move(
          _toLatLng(newLoc.latitude, newLoc.longitude),
          _mapController.camera.zoom.clamp(13.5, 18.5),
        );
      }
    }
  }

  List<fmap.Polyline> _buildRoutePolylines() {
    final result = <fmap.Polyline>[];

    // Background polylines (alternatives)
    for (final polyline in widget.polylines) {
      if (polyline.points.isEmpty) continue;

      result.add(
        fmap.Polyline(
          points: polyline.points
              .map((point) => _toLatLng(point.latitude, point.longitude))
              .toList(),
          color: polyline.color.withOpacity(0.20),
          strokeWidth: polyline.width.toDouble() + 6,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );

      result.add(
        fmap.Polyline(
          points: polyline.points
              .map((point) => _toLatLng(point.latitude, point.longitude))
              .toList(),
          color: polyline.color,
          strokeWidth: polyline.width.toDouble(),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    // Active journey selected route with Completed vs Remaining split
    if (widget.activePolylinePoints != null &&
        widget.activePolylinePoints!.isNotEmpty) {
      final allPoints = widget.activePolylinePoints!;
      final splitIdx =
          (widget.completedPolylineIndex ?? 0).clamp(0, allPoints.length - 1);

      if (widget.isNavigating && splitIdx > 0) {
        // 1. Completed portion (muted gray)
        final completedPts = allPoints
            .sublist(0, splitIdx + 1)
            .map((p) => _toLatLng(p.latitude, p.longitude))
            .toList();

        if (completedPts.length > 1) {
          result.add(
            fmap.Polyline(
              points: completedPts,
              color: Colors.grey.withOpacity(0.55),
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          );
        }
      }

      // 2. Remaining portion (vibrant SafeHer green)
      final startIdx = widget.isNavigating ? splitIdx : 0;
      final remainingPts = allPoints
          .sublist(startIdx)
          .map((p) => _toLatLng(p.latitude, p.longitude))
          .toList();

      if (remainingPts.isNotEmpty) {
        result.add(
          fmap.Polyline(
            points: remainingPts,
            color: AppColors.safeGreen.withOpacity(0.25),
            strokeWidth: 14,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );

        result.add(
          fmap.Polyline(
            points: remainingPts,
            color: AppColors.safeGreen,
            strokeWidth: 7,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
      }
    }

    return result;
  }

  Widget _navigationArrowPuck(double bearing) {
    return Transform.rotate(
      angle: bearing * math.pi / 180.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer halo
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.22),
            ),
          ),
          // White border
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          // Directional Arrow Puck
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blueDotMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing soft blue outer halo
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4285F4).withOpacity(0.24),
          ),
        ),
        // White border ring with elevation shadow
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        // Vibrant Google blue center dot
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1A73E8),
          ),
        ),
      ],
    );
  }

  Widget _locationMarker({
    required Color color,
    required IconData icon,
    double size = 42,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: color.withOpacity(0.85),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.48,
      ),
    );
  }

  Widget _safeSpotMarker({
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 18,
      ),
    );
  }

  /// Shows a bottom-sheet callout when a map marker is tapped.
  void _showMarkerCallout(BuildContext context, {
    required String name,
    required String type,
    required IconData icon,
    required Color color,
    String? extra,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.12),
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (extra != null) ...[
                const SizedBox(height: 12),
                Text(extra, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<fmap.Marker> _buildSafetyMarkers() {
    final markers = <fmap.Marker>[];
    final spots = widget.safeSpots;
    if (spots == null) return markers;

    if (widget.showPolice) {
      for (final police in spots.policeStations) {
        markers.add(
          fmap.Marker(
            point: _toLatLng(police.latitude, police.longitude),
            width: 38,
            height: 38,
            child: GestureDetector(
              onTap: () => _showMarkerCallout(
                context,
                name: police.name,
                type: 'Police Station',
                icon: Icons.local_police,
                color: Colors.blue.shade700,
              ),
              child: Tooltip(
                message: police.name,
                child: _safeSpotMarker(
                  color: Colors.blue.shade700,
                  icon: Icons.local_police,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (widget.showHospitals) {
      for (final hospital in spots.hospitals) {
        markers.add(
          fmap.Marker(
            point: _toLatLng(hospital.latitude, hospital.longitude),
            width: 38,
            height: 38,
            child: GestureDetector(
              onTap: () => _showMarkerCallout(
                context,
                name: hospital.name,
                type: 'Hospital',
                icon: Icons.local_hospital,
                color: Colors.red.shade700,
              ),
              child: Tooltip(
                message: hospital.name,
                child: _safeSpotMarker(
                  color: Colors.red.shade700,
                  icon: Icons.local_hospital,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (widget.showTransit) {
      for (final station in spots.transitStations) {
        markers.add(
          fmap.Marker(
            point: _toLatLng(station.latitude, station.longitude),
            width: 38,
            height: 38,
            child: GestureDetector(
              onTap: () => _showMarkerCallout(
                context,
                name: station.name,
                type: 'Transit Station',
                icon: Icons.directions_transit,
                color: Colors.orange.shade700,
              ),
              child: Tooltip(
                message: station.name,
                child: _safeSpotMarker(
                  color: Colors.orange.shade700,
                  icon: Icons.directions_transit,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (widget.showBlackspots) {
      for (final blackspot in spots.accidentBlackspots) {
        markers.add(
          fmap.Marker(
            point: _toLatLng(blackspot.latitude, blackspot.longitude),
            width: 38,
            height: 38,
            child: GestureDetector(
              onTap: () => _showMarkerCallout(
                context,
                name: blackspot.name,
                type: 'Accident Blackspot',
                icon: Icons.warning_amber_rounded,
                color: Colors.deepPurple.shade700,
                extra: 'This area has a history of accidents. Exercise caution.',
              ),
              child: Tooltip(
                message: blackspot.name,
                child: _safeSpotMarker(
                  color: Colors.deepPurple.shade700,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<fmap.Marker> _buildMainMarkers() {
    final result = <fmap.Marker>[];

    for (final marker in widget.markers) {
      final id = marker.markerId.value.toLowerCase();
      Color color;
      IconData icon;

      if (id.contains('origin') || id.contains('user')) {
        color = Colors.cyan.shade700;
        icon = Icons.my_location;
      } else if (id.contains('dest')) {
        color = AppColors.accent;
        icon = Icons.location_on;
      } else {
        color = AppColors.primary;
        icon = Icons.location_on;
      }

      final title = marker.infoWindow.title;
      result.add(
        fmap.Marker(
          point: _toLatLng(
            marker.position.latitude,
            marker.position.longitude,
          ),
          width: 46,
          height: 46,
          child: Tooltip(
            message: title ?? 'SafeHer AI location',
            child: _locationMarker(
              color: color,
              icon: icon,
            ),
          ),
        ),
      );
    }

    return result;
  }

  List<fmap.Marker> _buildJourneyMarkers() {
    final result = <fmap.Marker>[];

    if (widget.userLocation != null) {
      if (widget.isNavigating) {
        // Real-Time Turn-by-Turn Navigation Arrow / Puck
        result.add(
          fmap.Marker(
            point: _toLatLng(
              widget.userLocation!.latitude,
              widget.userLocation!.longitude,
            ),
            width: 52,
            height: 52,
            child: _navigationArrowPuck(widget.userBearing ?? 0.0),
          ),
        );
      } else {
        // Real-Time Google-Maps-Style Blue Dot Location Marker
        result.add(
          fmap.Marker(
            point: _toLatLng(
              widget.userLocation!.latitude,
              widget.userLocation!.longitude,
            ),
            width: 44,
            height: 44,
            child: Tooltip(
              message: 'Your Current Location',
              child: _blueDotMarker(),
            ),
          ),
        );
      }
    }

    if (widget.destinationLocation != null) {
      result.add(
        fmap.Marker(
          point: _toLatLng(
            widget.destinationLocation!.latitude,
            widget.destinationLocation!.longitude,
          ),
          width: 48,
          height: 48,
          child: _locationMarker(
            color: AppColors.accent,
            icon: Icons.flag_rounded,
            size: 46,
          ),
        ),
      );
    }

    return result;
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom + 1).clamp(3.0, 19.0),
    );
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom - 1).clamp(3.0, 19.0),
    );
  }

  void _recenter() {
    if (widget.onRecenter != null) {
      widget.onRecenter!();
    }
    if (widget.userLocation != null) {
      _mapController.move(
        _toLatLng(
          widget.userLocation!.latitude,
          widget.userLocation!.longitude,
        ),
        16.0,
      );
    } else {
      _mapController.move(
        _toLatLng(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        ),
        13.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final centerTarget = widget.userLocation != null
        ? _toLatLng(widget.userLocation!.latitude, widget.userLocation!.longitude)
        : _toLatLng(widget.initialCenter.latitude, widget.initialCenter.longitude);

    final allMarkers = <fmap.Marker>[
      ..._buildSafetyMarkers(),
      ..._buildMainMarkers(),
      ..._buildJourneyMarkers(),
    ];

    return Stack(
      children: [
        // REAL OPENSTREETMAP / LEAFLET-STYLE MAP
        fmap.FlutterMap(
          mapController: _mapController,
          options: fmap.MapOptions(
            initialCenter: centerTarget,
            initialZoom: widget.isNavigating ? 16.5 : 14.0,
            minZoom: 5,
            maxZoom: 19,
            interactionOptions: const fmap.InteractionOptions(
              flags: fmap.InteractiveFlag.all,
            ),
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture && widget.onPanStart != null) {
                widget.onPanStart!();
              }
            },
          ),
          children: [
            fmap.TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.safeher_ai',
            ),
            if (_buildRoutePolylines().isNotEmpty)
              fmap.PolylineLayer(
                polylines: _buildRoutePolylines(),
              ),
            if (allMarkers.isNotEmpty)
              fmap.MarkerLayer(
                markers: allMarkers,
              ),
            const fmap.RichAttributionWidget(
              attributions: [
                fmap.TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),

        // SafeHer map identity (shown when browsing/home map, hidden during active navigation HUD)
        if (!widget.isNavigating)
          Positioned(
            top: 14,
            left: 16,
            child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.corridorTitle ?? 'SafeHer AI',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Map controls
        Positioned(
          right: 14,
          bottom: 210,
          child: Column(
            children: [
              _mapControl(
                icon: Icons.add,
                onPressed: _zoomIn,
              ),
              const SizedBox(height: 7),
              _mapControl(
                icon: Icons.remove,
                onPressed: _zoomOut,
              ),
              const SizedBox(height: 7),
              _mapControl(
                icon: widget.isCameraFollowing
                    ? Icons.navigation_rounded
                    : Icons.my_location,
                iconColor: widget.isCameraFollowing
                    ? AppColors.primary
                    : AppColors.textPrimary,
                onPressed: _recenter,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapControl({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}