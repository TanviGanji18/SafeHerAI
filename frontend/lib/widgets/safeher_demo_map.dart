import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';
import '../models/route_model.dart';
import '../models/amenity_model.dart';

/// A polished, interactive vector map canvas used in development & demo mode
/// when Google Maps API billing / key is not yet configured.
///
/// It visually projects actual coordinates, polylines, and safety markers
/// without instantiating the native Android Google Play Services MapView,
/// preventing the `IllegalStateException: API key not found` crash.
class SafeHerDemoMap extends StatefulWidget {
  final LatLng initialCenter;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final List<CoordinatePoint>? activePolylinePoints;
  final CoordinatePoint? userLocation;
  final CoordinatePoint? destinationLocation;
  final NearbySafeSpots? safeSpots;
  final bool showPolice;
  final bool showHospitals;
  final bool showTransit;
  final bool showBlackspots;
  final String? corridorTitle;

  const SafeHerDemoMap({
    Key? key,
    this.initialCenter = const LatLng(AppConstants.hyderabadCenterLat, AppConstants.hyderabadCenterLon),
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
  }) : super(key: key);

  @override
  State<SafeHerDemoMap> createState() => _SafeHerDemoMapState();
}

class _SafeHerDemoMapState extends State<SafeHerDemoMap> {
  final TransformationController _transformController = TransformationController();

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final matrix = _transformController.value.clone();
    matrix.scale(1.25, 1.25);
    _transformController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformController.value.clone();
    matrix.scale(0.8, 0.8);
    _transformController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE9EDF2),
      child: Stack(
        children: [
          // 1. Interactive Panning & Zooming Map Canvas
          InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(300),
            minScale: 0.6,
            maxScale: 3.5,
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _HyderabadMapCanvasPainter(
                  polylines: widget.polylines,
                  markers: widget.markers,
                  activePolylinePoints: widget.activePolylinePoints,
                  userLocation: widget.userLocation,
                  destinationLocation: widget.destinationLocation,
                  safeSpots: widget.safeSpots,
                  showPolice: widget.showPolice,
                  showHospitals: widget.showHospitals,
                  showTransit: widget.showTransit,
                  showBlackspots: widget.showBlackspots,
                ),
              ),
            ),
          ),

          // 2. Subtle Watermark & Mode Pill
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.corridorTitle ?? 'SafeHer AI • Demo Map',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Demo Canvas',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Quick Map Controls (Zoom In, Zoom Out, Center)
          Positioned(
            right: 14,
            bottom: 220,
            child: Column(
              children: [
                _buildMapControlBtn(icon: Icons.add, onPressed: _zoomIn),
                const SizedBox(height: 6),
                _buildMapControlBtn(icon: Icons.remove, onPressed: _zoomOut),
                const SizedBox(height: 6),
                _buildMapControlBtn(icon: Icons.my_location, onPressed: _resetZoom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlBtn({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.textPrimary),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}

class _HyderabadMapCanvasPainter extends CustomPainter {
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final List<CoordinatePoint>? activePolylinePoints;
  final CoordinatePoint? userLocation;
  final CoordinatePoint? destinationLocation;
  final NearbySafeSpots? safeSpots;
  final bool showPolice;
  final bool showHospitals;
  final bool showTransit;
  final bool showBlackspots;

  // Hyderabad bounding coordinates for projection
  static const double minLat = 17.3000;
  static const double maxLat = 17.5200;
  static const double minLon = 78.3000;
  static const double maxLon = 78.5800;

  _HyderabadMapCanvasPainter({
    required this.polylines,
    required this.markers,
    this.activePolylinePoints,
    this.userLocation,
    this.destinationLocation,
    this.safeSpots,
    required this.showPolice,
    required this.showHospitals,
    required this.showTransit,
    required this.showBlackspots,
  });

  Offset _project(double lat, double lon, Size size) {
    // Mercator-like 2D projection normalized to canvas size
    final nx = (lon - minLon) / (maxLon - minLon);
    final ny = (maxLat - lat) / (maxLat - minLat); // Invert Y (screen coords)
    return Offset(
      (nx * size.width).clamp(0.0, size.width),
      (ny * size.height).clamp(0.0, size.height),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid Roads & Urban Corridors
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFFDCE2EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final waterPaint = Paint()
      ..color = const Color(0xFFCDE5F7)
      ..style = PaintingStyle.fill;

    // Hussain Sagar Lake in central Hyderabad
    final lakeCenter = _project(17.4239, 78.4738, size);
    canvas.drawOval(
      Rect.fromCenter(center: lakeCenter, width: 70, height: 55),
      waterPaint,
    );

    // Osman Sagar / Gandipet in West Hyderabad
    final osmanCenter = _project(17.3750, 78.3150, size);
    canvas.drawOval(
      Rect.fromCenter(center: osmanCenter, width: 60, height: 45),
      waterPaint,
    );

    // Major Hyderabad arterial network lines
    final arteries = [
      // Outer Ring Road (ORR West / North arc)
      [_project(17.3400, 78.3300, size), _project(17.4300, 78.3500, size), _project(17.4900, 78.3800, size), _project(17.5100, 78.4800, size)],
      // Hitec City to Secunderabad Corridor (via Begumpet)
      [_project(17.4435, 78.3772, size), _project(17.4260, 78.4120, size), _project(17.4420, 78.4680, size), _project(17.4399, 78.4983, size)],
      // Gachibowli to Banjara Hills
      [_project(17.4400, 78.3489, size), _project(17.4300, 78.3900, size), _project(17.4156, 78.4350, size)],
      // Old City / Charminar to Lakdikapul
      [_project(17.3616, 78.4747, size), _project(17.3900, 78.4700, size), _project(17.4050, 78.4600, size)],
      // Kukatpally to Ameerpet
      [_project(17.4938, 78.3995, size), _project(17.4600, 78.4200, size), _project(17.4375, 78.4482, size)],
    ];

    for (final artery in arteries) {
      final path = Path()..moveTo(artery[0].dx, artery[0].dy);
      for (int i = 1; i < artery.length; i++) {
        path.lineTo(artery[i].dx, artery[i].dy);
      }
      canvas.drawPath(path, roadPaint);
    }

    // Secondary urban grid lines
    for (double y = 40; y < size.height; y += 75) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), secondaryRoadPaint);
    }
    for (double x = 40; x < size.width; x += 75) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), secondaryRoadPaint);
    }

    // 2. Draw Landmark Corridor Labels
    final landmarks = [
      {'name': 'Hitec City', 'pos': _project(17.4435, 78.3772, size)},
      {'name': 'Gachibowli', 'pos': _project(17.4400, 78.3489, size)},
      {'name': 'Jubilee Hills', 'pos': _project(17.4310, 78.4070, size)},
      {'name': 'Banjara Hills', 'pos': _project(17.4156, 78.4350, size)},
      {'name': 'Begumpet', 'pos': _project(17.4420, 78.4680, size)},
      {'name': 'Secunderabad', 'pos': _project(17.4399, 78.4983, size)},
      {'name': 'Charminar', 'pos': _project(17.3616, 78.4747, size)},
      {'name': 'Kukatpally', 'pos': _project(17.4938, 78.3995, size)},
    ];

    for (final lm in landmarks) {
      final pos = lm['pos'] as Offset;
      final name = lm['name'] as String;

      // Small hub dot
      canvas.drawCircle(pos, 3.5, Paint()..color = const Color(0xFF94A3B8));

      final textSpan = TextSpan(
        text: name,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(pos.dx + 6, pos.dy - 6));
    }

    // 3. Draw Actual Route Polylines (if available from selected route or active journey)
    if (activePolylinePoints != null && activePolylinePoints!.isNotEmpty) {
      _drawRoutePoints(canvas, size, activePolylinePoints!, AppColors.safeGreen, 6.0);
    } else {
      for (final poly in polylines) {
        if (poly.points.isNotEmpty) {
          final pts = poly.points.map((p) => CoordinatePoint(latitude: p.latitude, longitude: p.longitude)).toList();
          _drawRoutePoints(canvas, size, pts, poly.color, poly.width.toDouble().clamp(3.0, 7.0));
        }
      }
    }

    // 4. Draw Markers (Police, Hospitals, Transit, Blackspots, Origin, Destination)
    if (safeSpots != null) {
      if (showPolice) {
        for (final p in safeSpots!.policeStations) {
          _drawPin(canvas, _project(p.latitude, p.longitude, size), Colors.blue.shade700, Icons.local_police);
        }
      }
      if (showHospitals) {
        for (final h in safeSpots!.hospitals) {
          _drawPin(canvas, _project(h.latitude, h.longitude, size), Colors.red.shade700, Icons.local_hospital);
        }
      }
      if (showTransit) {
        for (final t in safeSpots!.transitStations) {
          _drawPin(canvas, _project(t.latitude, t.longitude, size), Colors.orange.shade700, Icons.directions_subway);
        }
      }
      if (showBlackspots) {
        for (final b in safeSpots!.accidentBlackspots) {
          _drawPin(canvas, _project(b.latitude, b.longitude, size), Colors.purple.shade700, Icons.warning_amber);
        }
      }
    }

    // Draw GoogleMap markers passed in widget
    for (final m in markers) {
      final pos = _project(m.position.latitude, m.position.longitude, size);
      if (m.markerId.value.contains('origin') || m.markerId.value.contains('user')) {
        _drawPulsingUserPin(canvas, pos, Colors.cyan.shade600);
      } else if (m.markerId.value.contains('dest')) {
        _drawDestinationPin(canvas, pos, AppColors.accent);
      } else {
        _drawPin(canvas, pos, AppColors.primary, Icons.location_on);
      }
    }

    if (userLocation != null) {
      final pos = _project(userLocation!.latitude, userLocation!.longitude, size);
      _drawPulsingUserPin(canvas, pos, Colors.cyan.shade600);
    }

    if (destinationLocation != null) {
      final pos = _project(destinationLocation!.latitude, destinationLocation!.longitude, size);
      _drawDestinationPin(canvas, pos, AppColors.accent);
    }
  }

  void _drawRoutePoints(Canvas canvas, Size size, List<CoordinatePoint> points, Color color, double width) {
    if (points.isEmpty) return;

    // Glowing outer stroke
    final glowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Core stroke
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final first = _project(points.first.latitude, points.first.longitude, size);
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < points.length; i++) {
      final pt = _project(points[i].latitude, points[i].longitude, size);
      path.lineTo(pt.dx, pt.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);

    // Start & End indicator dots
    final startPt = _project(points.first.latitude, points.first.longitude, size);
    final endPt = _project(points.last.latitude, points.last.longitude, size);
    _drawPulsingUserPin(canvas, startPt, Colors.cyan.shade600);
    _drawDestinationPin(canvas, endPt, AppColors.accent);
  }

  void _drawPin(Canvas canvas, Offset pos, Color color, IconData icon) {
    canvas.drawCircle(pos, 5.0, Paint()..color = color);
    canvas.drawCircle(pos, 7.5, Paint()..color = color.withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawPulsingUserPin(Canvas canvas, Offset pos, Color color) {
    // Outer pulse ring
    canvas.drawCircle(pos, 13.0, Paint()..color = color.withOpacity(0.25));
    // Middle ring
    canvas.drawCircle(pos, 8.0, Paint()..color = Colors.white);
    // Center point
    canvas.drawCircle(pos, 5.5, Paint()..color = color);
  }

  void _drawDestinationPin(Canvas canvas, Offset pos, Color color) {
    // Outer pin badge
    canvas.drawCircle(pos, 10.0, Paint()..color = color);
    canvas.drawCircle(pos, 6.0, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 4.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HyderabadMapCanvasPainter oldDelegate) {
    return true;
  }
}
