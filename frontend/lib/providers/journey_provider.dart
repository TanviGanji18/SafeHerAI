import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_model.dart';
import '../models/journey_model.dart';
import '../models/navigation_model.dart';
import '../models/sos_model.dart';
import '../services/api_service.dart';
import '../services/local_journey_store.dart';
import '../services/firebase_service.dart';

class JourneyProvider with ChangeNotifier {
  final ApiService apiService;
  LocalJourneyStore? _localStore;

  ActiveJourney? _activeJourney;
  bool _isNavigating = false;
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  double _remainingDistanceKm = 0.0;
  double _remainingDurationMin = 0.0;
  bool _isDestinationReached = false;
  bool _emergencyActive = false;
  SOSResponse? _lastSOSResponse;
  String _currentInstruction = 'Follow the recommended safer corridor';
  int _completedPolylineIndex = 0;
  double _currentBearing = 0.0;
  LatLng? _lastBearingAnchorLocation;
  bool _isOffRoute = false;
  bool _isCameraFollowing = true;
  bool _isRecalculating = false;

  // Turn-by-turn maneuvers
  List<NavigationStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  double _distanceToNextManeuverMeters = 0.0;

  // GPS subscription
  StreamSubscription<Position>? _positionSubscription;

  // Stored history
  List<ActiveJourney> _journeyHistory = [];
  bool _isLoadingHistory = false;

  JourneyProvider({required this.apiService});

  ActiveJourney? get activeJourney => _activeJourney;
  bool get isNavigating => _isNavigating;
  LatLng? get currentLocation => _currentLocation;
  LatLng? get destinationLocation => _destinationLocation;
  double get remainingDistanceKm => _remainingDistanceKm;
  double get remainingDurationMin => _remainingDurationMin;
  bool get isDestinationReached => _isDestinationReached;
  bool get emergencyActive => _emergencyActive;
  SOSResponse? get lastSOSResponse => _lastSOSResponse;
  String get currentInstruction => _currentInstruction;
  int get currentPolylineIndex => _completedPolylineIndex;
  int get completedPolylineIndex => _completedPolylineIndex;
  double get currentBearing => _currentBearing;
  bool get isOffRoute => _isOffRoute;
  bool get isCameraFollowing => _isCameraFollowing;
  bool get isRecalculating => _isRecalculating;
  List<NavigationStep> get navigationSteps => _navigationSteps;
  int get currentStepIndex => _currentStepIndex;
  double get distanceToNextManeuverMeters => _distanceToNextManeuverMeters;

  NavigationStep? get currentStep =>
      _navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length
          ? _navigationSteps[_currentStepIndex]
          : null;

  NavigationStep? get nextStep =>
      _navigationSteps.isNotEmpty && _currentStepIndex + 1 < _navigationSteps.length
          ? _navigationSteps[_currentStepIndex + 1]
          : null;

  List<ActiveJourney> get journeyHistory => _journeyHistory;
  bool get isLoadingHistory => _isLoadingHistory;

  void setCameraFollowing(bool following) {
    if (_isCameraFollowing != following) {
      _isCameraFollowing = following;
      notifyListeners();
    }
  }

  // Haversine distance helper (in kilometers)
  static double _calculateDistanceKm(LatLng a, LatLng b) {
    const double earthRadiusKm = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final sinLat = math.sin(dLat / 2.0);
    final sinLon = math.sin(dLon / 2.0);
    final h = sinLat * sinLat +
        math.cos(a.latitude * math.pi / 180.0) *
            math.cos(b.latitude * math.pi / 180.0) *
            sinLon * sinLon;
    return 2.0 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  // Cumulative polyline distance between two indices [fromIdx, toIdx] in meters
  static double _calculatePolylineDistanceMeters(
    List<CoordinatePoint> coords,
    int fromIdx,
    int toIdx,
  ) {
    if (coords.isEmpty || fromIdx >= toIdx) return 0.0;
    final start = fromIdx.clamp(0, coords.length - 1);
    final end = toIdx.clamp(0, coords.length - 1);
    double totalMeters = 0.0;
    for (int i = start; i < end; i++) {
      totalMeters += _calculateDistanceKm(
        LatLng(coords[i].latitude, coords[i].longitude),
        LatLng(coords[i + 1].latitude, coords[i + 1].longitude),
      ) * 1000.0;
    }
    return totalMeters;
  }

  // Bearing helper in degrees [0, 360)
  static double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180.0;
    final lon1 = from.longitude * math.pi / 180.0;
    final lat2 = to.latitude * math.pi / 180.0;
    final lon2 = to.longitude * math.pi / 180.0;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }

  // 1. Start Journey
  Future<bool> startJourney({
    EnrichedRoute? route,
    EnrichedRoute? selectedRoute,
    Map<String, dynamic>? origin,
    Map<String, dynamic>? destination,
    String? originName,
    String? destName,
    Map<String, dynamic>? originCoords,
    Map<String, dynamic>? destCoords,
    String userId = 'anonymous_user',
  }) async {
    final actualRoute = route ?? selectedRoute;
    if (actualRoute == null) return false;

    final actualOrigin = origin ?? {
      'address': originName ?? 'Starting point',
      'lat': originCoords?['lat'] ?? 0.0,
      'lon': originCoords?['lon'] ?? 0.0,
    };
    final actualDest = destination ?? {
      'address': destName ?? 'Destination',
      'lat': destCoords?['lat'] ?? 0.0,
      'lon': destCoords?['lon'] ?? 0.0,
    };

    final now = DateTime.now();
    final tempJourneyId = 'JRN-${now.millisecondsSinceEpoch}';

    _activeJourney = ActiveJourney(
      journeyId: tempJourneyId,
      userId: userId,
      origin: actualOrigin,
      destination: actualDest,
      selectedRoute: actualRoute,
      distanceKm: actualRoute.distanceKm,
      durationMin: actualRoute.durationMin,
      safetyScore: actualRoute.safetyScore,
      startTime: now,
      journeyStatus: 'active',
      emergencyOccurred: false,
    );

    _isNavigating = true;
    _isDestinationReached = false;
    _emergencyActive = false;
    _remainingDistanceKm = actualRoute.distanceKm;
    _remainingDurationMin = actualRoute.durationMin;
    _completedPolylineIndex = 0;
    _currentStepIndex = 0;
    _isOffRoute = false;
    _isCameraFollowing = true;
    _currentBearing = 0.0;

    if (actualRoute.polylineCoords.isNotEmpty) {
      _currentLocation = LatLng(
        actualRoute.polylineCoords.first.latitude,
        actualRoute.polylineCoords.first.longitude,
      );
      _destinationLocation = LatLng(
        actualRoute.polylineCoords.last.latitude,
        actualRoute.polylineCoords.last.longitude,
      );

      if (actualRoute.polylineCoords.length > 1) {
        _currentBearing = _calculateBearing(
          _currentLocation!,
          LatLng(
            actualRoute.polylineCoords[1].latitude,
            actualRoute.polylineCoords[1].longitude,
          ),
        );
      }
      _lastBearingAnchorLocation = _currentLocation;
    }

    // Populate steps
    if (actualRoute.steps.isNotEmpty) {
      _navigationSteps = List.from(actualRoute.steps);
    } else if (actualRoute.polylineCoords.isNotEmpty) {
      _navigationSteps = _generateFallbackDartSteps(
        actualRoute.polylineCoords,
        actualRoute.summary,
      );
    } else {
      _navigationSteps = [];
    }

    if (_navigationSteps.isNotEmpty) {
      final firstStep = _navigationSteps.first;
      double initialManeuverMeters = 0.0;
      if (actualRoute.polylineCoords.isNotEmpty) {
        int targetIdx = actualRoute.polylineCoords.length - 1;
        if (_navigationSteps.length > 1) {
          final nextCoord = LatLng(_navigationSteps[1].latitude, _navigationSteps[1].longitude);
          double minDist = double.infinity;
          for (int i = 0; i < actualRoute.polylineCoords.length; i++) {
            final d = _calculateDistanceKm(nextCoord, LatLng(actualRoute.polylineCoords[i].latitude, actualRoute.polylineCoords[i].longitude));
            if (d < minDist) {
              minDist = d;
              targetIdx = i;
            }
          }
        }
        initialManeuverMeters = _calculatePolylineDistanceMeters(actualRoute.polylineCoords, 0, targetIdx);
      }
      if (initialManeuverMeters <= 0.0 && firstStep.distanceMeters > 0) {
        initialManeuverMeters = firstStep.distanceMeters;
      }
      _distanceToNextManeuverMeters = math.max(0.0, initialManeuverMeters);

      if (_distanceToNextManeuverMeters > 30.0 && _navigationSteps.length > 1) {
        final distStr = _formatDistanceMeters(_distanceToNextManeuverMeters);
        _currentInstruction = '$distStr: ${firstStep.instruction}';
      } else {
        _currentInstruction = firstStep.instruction;
      }
    } else {
      _currentInstruction = 'Follow the recommended safer corridor';
    }

    notifyListeners();

    // Start live GPS tracking
    _initGpsTracking();

    // Fetch live OSRM navigation in background to enrich steps if needed
    _fetchLiveNavigationSteps(actualRoute);

    try {
      // Backend registration
      final res = await apiService.startJourney(
        userId: userId,
        origin: actualOrigin,
        destination: actualDest,
        route: actualRoute,
      );
      if (res['journey_id'] != null) {
        _activeJourney = ActiveJourney(
          journeyId: res['journey_id'],
          userId: userId,
          origin: actualOrigin,
          destination: actualDest,
          selectedRoute: actualRoute,
          distanceKm: actualRoute.distanceKm,
          durationMin: actualRoute.durationMin,
          safetyScore: actualRoute.safetyScore,
          startTime: now,
          journeyStatus: 'active',
        );
      }

      // Firestore sync
      if (_activeJourney != null) {
        await FirebaseService.syncJourney(_activeJourney!);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[JourneyProvider] Start journey server note: $e');
      return true;
    }
  }

  // Background fetch of full OSRM steps
  Future<void> _fetchLiveNavigationSteps(EnrichedRoute route) async {
    if (route.polylineCoords.length < 2) return;
    try {
      final origin = route.polylineCoords.first;
      final dest = route.polylineCoords.last;
      final navRoute = await apiService.getNavigationRoute(
        originLat: origin.latitude,
        originLon: origin.longitude,
        destLat: dest.latitude,
        destLon: dest.longitude,
      );

      if (navRoute.steps.isNotEmpty && _isNavigating && !_isDestinationReached) {
        _navigationSteps = navRoute.steps;
        if (_currentStepIndex < _navigationSteps.length) {
          _currentInstruction = _navigationSteps[_currentStepIndex].instruction;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[JourneyProvider] Live OSRM background fetch note: $e');
    }
  }

  // Live GPS tracking initialization
  Future<void> _initGpsTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[JourneyProvider] Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[JourneyProvider] Location permission not granted.');
        return;
      }

      try {
        Position? pos;
        try {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8),
          );
        } catch (_) {
          pos = await Geolocator.getLastKnownPosition();
        }
        if (pos != null) {
          handlePositionUpdate(pos);
        }
      } catch (e) {
        debugPrint('[JourneyProvider] Initial GPS position note: $e');
      }

      await _positionSubscription?.cancel();

      LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(milliseconds: 1000),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position pos) {
          handlePositionUpdate(pos);
        },
        onError: (err) {
          debugPrint('[JourneyProvider] GPS stream note: $err');
        },
      );
    } catch (e) {
      debugPrint('[JourneyProvider] Init GPS tracking note: $e');
    }
  }

  /// Handles incoming GPS position fixes, updating coordinates, accumulated movement bearing,
  /// and turn-by-turn navigation progress.
  void handlePositionUpdate(Position pos) {
    if (!_isNavigating || _isDestinationReached) return;

    final newLoc = LatLng(pos.latitude, pos.longitude);
    double bearing = _currentBearing;

    // 1. Check for reliable device heading from sensor/GPS when moving or compass accuracy is good
    final hasSpeed = pos.speed > 0.3;
    final hasValidHeading = pos.heading > 0.0 && pos.heading <= 360.0;
    final hasGoodHeadingAccuracy = !pos.hasHeadingAccuracy || pos.headingAccuracy <= 45.0;

    if (hasValidHeading && (hasSpeed || hasGoodHeadingAccuracy)) {
      bearing = pos.heading;
      _lastBearingAnchorLocation = newLoc;
    } else {
      // 2. Continuous displacement-based bearing calculation
      // Accumulates small walking steps until at least 2 meters from anchor are covered
      if (_lastBearingAnchorLocation == null) {
        _lastBearingAnchorLocation = newLoc;
      } else {
        final distFromAnchorKm = _calculateDistanceKm(_lastBearingAnchorLocation!, newLoc);
        if (distFromAnchorKm >= 0.002) {
          bearing = _calculateBearing(_lastBearingAnchorLocation!, newLoc);
          _lastBearingAnchorLocation = newLoc;
        }
      }
    }

    _currentBearing = bearing;
    updateLocation(newLoc);
  }

  // 2. Location Tracking, Polyline Snapping & Maneuver Progress
  void updateLocation(LatLng newLocation) {
    _currentLocation = newLocation;

    if (_activeJourney != null &&
        _activeJourney!.selectedRoute.polylineCoords.isNotEmpty) {
      final coords = _activeJourney!.selectedRoute.polylineCoords;

      // Find closest polyline point (snap to route)
      double minDistanceKm = double.infinity;
      int bestIdx = _completedPolylineIndex;

      final searchStart = math.max(0, _completedPolylineIndex - 2);
      for (int i = searchStart; i < coords.length; i++) {
        final pt = LatLng(coords[i].latitude, coords[i].longitude);
        final d = _calculateDistanceKm(newLocation, pt);
        if (d < minDistanceKm) {
          minDistanceKm = d;
          bestIdx = i;
        }
      }

      // Check off-route: threshold > 65 meters (0.065 km)
      _isOffRoute = minDistanceKm > 0.065;

      // Only advance completed segment when on-route.
      // Off-route GPS fixes (e.g., intercontinental positions) would otherwise
      // snap to the last polyline point and trigger false arrival detection.
      if (!_isOffRoute && bestIdx > _completedPolylineIndex) {
        _completedPolylineIndex = bestIdx;
      }

      // 1. Calculate remaining route distance (corridor-grounded, avoiding intercontinental off-route jumps)
      if (_isOffRoute) {
        // Off-route: remaining corridor distance is from current snapped waypoint to destination
        final remMeters = _calculatePolylineDistanceMeters(
          coords,
          _completedPolylineIndex,
          coords.length - 1,
        );
        _remainingDistanceKm = remMeters > 0 ? remMeters / 1000.0 : _activeJourney!.distanceKm;
      } else {
        // On-route: distance from current location to snapped point + remaining route polyline
        final distToSnapped = _calculateDistanceKm(
          newLocation,
          LatLng(coords[_completedPolylineIndex].latitude, coords[_completedPolylineIndex].longitude),
        );
        final remMeters = _calculatePolylineDistanceMeters(
          coords,
          _completedPolylineIndex,
          coords.length - 1,
        );
        _remainingDistanceKm = distToSnapped + (remMeters / 1000.0);
      }

      if (_activeJourney!.distanceKm > 0) {
        final progressRatio =
            1.0 - (_remainingDistanceKm / _activeJourney!.distanceKm).clamp(0.0, 1.0);
        _remainingDurationMin = (_activeJourney!.durationMin *
                (1.0 - progressRatio))
            .clamp(0.0, _activeJourney!.durationMin);
      }

      // 2. Arrival threshold: within 65m of destination or at final polyline vertex
      // Both conditions require !_isOffRoute to prevent false arrival when an
      // off-route GPS fix snaps to the last polyline point.
      final destPt = _destinationLocation ??
          LatLng(coords.last.latitude, coords.last.longitude);
      final distToDestKm = _calculateDistanceKm(newLocation, destPt);
      if (!_isOffRoute &&
          (distToDestKm <= 0.065 ||
              _completedPolylineIndex >= coords.length - 1)) {
        if (!_isDestinationReached) {
          _isDestinationReached = true;
          _remainingDistanceKm = 0.0;
          _remainingDurationMin = 0.0;
          _currentInstruction = 'Destination Reached!';
          stopLiveNavigation();
          notifyListeners();
          return;
        }
      }

      // 3. Turn-by-Turn Maneuver Instruction & Distance
      if (_navigationSteps.isNotEmpty &&
          _currentStepIndex < _navigationSteps.length) {
        final hasNextStep = _currentStepIndex < _navigationSteps.length - 1;
        final targetStep = hasNextStep
            ? _navigationSteps[_currentStepIndex + 1]
            : _navigationSteps.last;
        final targetCoord = LatLng(targetStep.latitude, targetStep.longitude);

        // Find polyline index for target coordinate
        int targetPolylineIdx = coords.length - 1;
        double minTargetDist = double.infinity;
        for (int i = _completedPolylineIndex; i < coords.length; i++) {
          final d = _calculateDistanceKm(
              targetCoord, LatLng(coords[i].latitude, coords[i].longitude));
          if (d < minTargetDist) {
            minTargetDist = d;
            targetPolylineIdx = i;
          }
        }

        double metersToManeuver;
        if (_isOffRoute) {
          // Off-route: calculate distance along planned route from current snapped point to target maneuver
          final alongRouteMeters = _calculatePolylineDistanceMeters(
            coords,
            _completedPolylineIndex,
            targetPolylineIdx,
          );
          if (alongRouteMeters > 0) {
            metersToManeuver = alongRouteMeters;
          } else if (_navigationSteps[_currentStepIndex].distanceMeters > 0) {
            metersToManeuver = _navigationSteps[_currentStepIndex].distanceMeters;
          } else {
            metersToManeuver = minTargetDist * 1000.0;
          }
        } else {
          // On-route: distance from current location to snapped point + polyline distance to target
          if (_completedPolylineIndex < targetPolylineIdx) {
            final toSnapped = _calculateDistanceKm(
                  newLocation,
                  LatLng(coords[_completedPolylineIndex].latitude,
                      coords[_completedPolylineIndex].longitude),
                ) *
                1000.0;
            final polylineMeters = _calculatePolylineDistanceMeters(
              coords,
              _completedPolylineIndex,
              targetPolylineIdx,
            );
            metersToManeuver = toSnapped + polylineMeters;
          } else {
            metersToManeuver =
                _calculateDistanceKm(newLocation, targetCoord) * 1000.0;
          }
        }

        _distanceToNextManeuverMeters = math.max(0.0, metersToManeuver);

        // If user reached maneuver or is within 30m, advance to next step
        if ((_distanceToNextManeuverMeters < 30.0 ||
                _completedPolylineIndex >= targetPolylineIdx) &&
            hasNextStep) {
          _currentStepIndex++;
          final nextTargetStep =
              (_currentStepIndex < _navigationSteps.length - 1)
                  ? _navigationSteps[_currentStepIndex + 1]
                  : _navigationSteps.last;
          final nextTargetCoord =
              LatLng(nextTargetStep.latitude, nextTargetStep.longitude);
          int nextTargetIdx = coords.length - 1;
          double nextMinDist = double.infinity;
          for (int i = _completedPolylineIndex; i < coords.length; i++) {
            final d = _calculateDistanceKm(nextTargetCoord,
                LatLng(coords[i].latitude, coords[i].longitude));
            if (d < nextMinDist) {
              nextMinDist = d;
              nextTargetIdx = i;
            }
          }
          final remMeters = _calculatePolylineDistanceMeters(
              coords, _completedPolylineIndex, nextTargetIdx);
          _distanceToNextManeuverMeters = remMeters > 0
              ? remMeters
              : _navigationSteps[_currentStepIndex].distanceMeters;
        }

        final activeStep = _navigationSteps[_currentStepIndex];
        if (_currentStepIndex == _navigationSteps.length - 1) {
          _currentInstruction = activeStep.instruction;
        } else if (_distanceToNextManeuverMeters > 30.0) {
          final distStr = _formatDistanceMeters(_distanceToNextManeuverMeters);
          _currentInstruction = '$distStr: ${activeStep.instruction}';
        } else {
          _currentInstruction = activeStep.instruction;
        }
      }
    }

    notifyListeners();
  }

  static String _formatDistanceMeters(double meters) {
    if (meters >= 1000) {
      return 'In ${(meters / 1000.0).toStringAsFixed(1)} km';
    } else {
      final rounded = (meters / 10).round() * 10;
      return 'In ${math.max(10, rounded)} m';
    }
  }

  // Recalculate route when off-route
  Future<void> recalculateRoute() async {
    if (_currentLocation == null ||
        _destinationLocation == null ||
        _isRecalculating) {
      return;
    }
    _isRecalculating = true;
    notifyListeners();

    try {
      final navRoute = await apiService.getNavigationRoute(
        originLat: _currentLocation!.latitude,
        originLon: _currentLocation!.longitude,
        destLat: _destinationLocation!.latitude,
        destLon: _destinationLocation!.longitude,
      );

      if (navRoute.polylineCoords.isNotEmpty && _activeJourney != null) {
        final currentRoute = _activeJourney!.selectedRoute;
        final updatedRoute = EnrichedRoute(
          routeId: currentRoute.routeId,
          summary: navRoute.summary.isNotEmpty ? navRoute.summary : currentRoute.summary,
          safetyScore: currentRoute.safetyScore,
          safetyTier: currentRoute.safetyTier,
          isRecommendedSafer: currentRoute.isRecommendedSafer,
          isFastest: currentRoute.isFastest,
          distanceKm: navRoute.distanceKm > 0 ? navRoute.distanceKm : currentRoute.distanceKm,
          durationMin: navRoute.durationMin > 0 ? navRoute.durationMin : currentRoute.durationMin,
          polylineCoords: navRoute.polylineCoords,
          encodedPolyline: currentRoute.encodedPolyline,
          components: currentRoute.components,
          contributions: currentRoute.contributions,
          rawFeatures: currentRoute.rawFeatures,
          steps: navRoute.steps,
        );

        _activeJourney = ActiveJourney(
          journeyId: _activeJourney!.journeyId,
          userId: _activeJourney!.userId,
          origin: _activeJourney!.origin,
          destination: _activeJourney!.destination,
          selectedRoute: updatedRoute,
          distanceKm: updatedRoute.distanceKm,
          durationMin: updatedRoute.durationMin,
          safetyScore: updatedRoute.safetyScore,
          startTime: _activeJourney!.startTime,
          journeyStatus: _activeJourney!.journeyStatus,
          emergencyOccurred: _activeJourney!.emergencyOccurred,
        );

        _navigationSteps = navRoute.steps;
        _currentStepIndex = 0;
        _completedPolylineIndex = 0;
        _isOffRoute = false;
        _remainingDistanceKm = updatedRoute.distanceKm;
        _remainingDurationMin = updatedRoute.durationMin;

        if (_navigationSteps.isNotEmpty) {
          _currentInstruction = _navigationSteps.first.instruction;
        }
      }
    } catch (e) {
      debugPrint('[JourneyProvider] Recalculate route note: $e');
    } finally {
      _isRecalculating = false;
      notifyListeners();
    }
  }

  // Advance navigation along route for testing / emulator simulation
  void advanceAlongRoute() {
    if (_activeJourney == null ||
        _activeJourney!.selectedRoute.polylineCoords.isEmpty) {
      return;
    }
    final coords = _activeJourney!.selectedRoute.polylineCoords;

    if (_completedPolylineIndex < coords.length - 1) {
      _completedPolylineIndex++;
      final target = coords[_completedPolylineIndex];
      final targetLoc = LatLng(target.latitude, target.longitude);

      if (_currentLocation != null) {
        _currentBearing = _calculateBearing(_currentLocation!, targetLoc);
      }
      updateLocation(targetLoc);
    } else {
      _isDestinationReached = true;
      _currentInstruction = 'Destination Reached!';
      stopLiveNavigation();
      notifyListeners();
    }
  }

  // Manual End / Destination Arrival Trigger
  void triggerDestinationReached() {
    _isDestinationReached = true;
    _currentInstruction = 'Destination Reached!';
    stopLiveNavigation();
    notifyListeners();
  }

  // Stop live navigation stream
  Future<void> stopLiveNavigation() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Fallback step generator in Dart
  List<NavigationStep> _generateFallbackDartSteps(
      List<CoordinatePoint> coords, String summary) {
    if (coords.isEmpty) return [];
    if (coords.length == 1) {
      return [
        NavigationStep(
          stepIndex: 0,
          instruction: 'Arrive at destination',
          maneuverType: 'arrive',
          roadName: summary,
          latitude: coords.first.latitude,
          longitude: coords.first.longitude,
        ),
      ];
    }

    final b0 = _calculateBearing(
      LatLng(coords[0].latitude, coords[0].longitude),
      LatLng(coords[1].latitude, coords[1].longitude),
    );
    double prevB = b0;

    final stepEntries = <Map<String, dynamic>>[
      {
        'instruction': 'Head towards destination on $summary',
        'maneuverType': 'depart',
        'modifier': 'straight',
        'coordIdx': 0,
        'bearing': b0,
      }
    ];

    for (int i = 1; i < coords.length - 1; i++) {
      final p1 = LatLng(coords[i].latitude, coords[i].longitude);
      final p2 = LatLng(coords[i + 1].latitude, coords[i + 1].longitude);
      final currB = _calculateBearing(p1, p2);
      final diff = ((currB - prevB + 180) % 360) - 180;

      if (diff.abs() >= 30.0) {
        final dir = diff > 0 ? 'right' : 'left';
        final mod = diff.abs() < 45 ? 'slight $dir' : dir;
        stepEntries.add({
          'instruction': 'Turn $mod onto $summary',
          'maneuverType': 'turn',
          'modifier': mod,
          'coordIdx': i,
          'bearing': currB,
        });
        prevB = currB;
      }
    }

    stepEntries.add({
      'instruction': 'Arrive at destination',
      'maneuverType': 'arrive',
      'modifier': null,
      'coordIdx': coords.length - 1,
      'bearing': prevB,
    });

    final steps = <NavigationStep>[];
    for (int idx = 0; idx < stepEntries.length; idx++) {
      final entry = stepEntries[idx];
      final coordIdx = entry['coordIdx'] as int;
      double stepDistM = 0.0;
      if (idx < stepEntries.length - 1) {
        final nextCoordIdx = stepEntries[idx + 1]['coordIdx'] as int;
        stepDistM = _calculatePolylineDistanceMeters(coords, coordIdx, nextCoordIdx);
      }
      final pt = coords[coordIdx];
      steps.add(NavigationStep(
        stepIndex: idx,
        instruction: entry['instruction'] as String,
        maneuverType: entry['maneuverType'] as String,
        modifier: entry['modifier'] as String?,
        roadName: summary,
        distanceMeters: (stepDistM * 10).round() / 10.0,
        durationSeconds: ((stepDistM / 1000.0 / 35.0) * 3600.0).roundToDouble(),
        latitude: pt.latitude,
        longitude: pt.longitude,
        bearing: entry['bearing'] as double?,
      ));
    }

    return steps;
  }

  // 3. SOS Emergency Trigger during Journey
  Future<bool> activateJourneySOS({int batteryLevel = 85, String? message}) async {
    _emergencyActive = true;
    if (_activeJourney != null) {
      _activeJourney!.emergencyOccurred = true;
    }

    final lat = _currentLocation?.latitude ?? 17.3850;
    final lon = _currentLocation?.longitude ?? 78.4867;
    final jId = _activeJourney?.journeyId ?? 'active_journey';

    final event = JourneyEvent(
      eventType: 'sos_trigger',
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      details: {'battery': batteryLevel, 'status': 'SOS_CONFIRMED'},
    );
    _activeJourney?.sosEvents.add(event);
    notifyListeners();

    try {
      await apiService.recordJourneyEvent(
        journeyId: jId,
        eventType: 'sos_trigger',
        latitude: lat,
        longitude: lon,
        details: {'battery': batteryLevel, 'message': message},
      );

      final sosRes = await apiService.triggerSOS(
        lat: lat,
        lon: lon,
        batteryLevel: batteryLevel,
        message: message ??
            'EMERGENCY: Immediate safety assistance requested during journey.',
        currentRouteId: _activeJourney?.selectedRoute.routeId,
      );
      _lastSOSResponse = sosRes;

      await FirebaseService.syncSOSEvent(
        journeyId: jId,
        userId: _activeJourney?.userId ?? 'anonymous_user',
        lat: lat,
        lon: lon,
        timestamp: DateTime.now(),
        metadata: {
          'alert_id': sosRes.alertId,
          'nearest_police': sosRes.nearestPoliceStation.name
        },
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[JourneyProvider] SOS dispatch note: $e');
      return true;
    }
  }

  // 4. Complete Journey & Submit User Feedback
  Future<bool> submitJourneyReport({
    required String routeExperience,
    required List<String> issuesNoticed,
    String? comments,
  }) async {
    if (_activeJourney == null) return false;

    stopLiveNavigation();

    final now = DateTime.now();
    _activeJourney!.endTime = now;
    _activeJourney!.journeyStatus = 'completed';

    final feedback = JourneyFeedback(
      routeExperience: routeExperience,
      issuesNoticed: issuesNoticed,
      comments: comments,
      submittedAt: now,
    );
    _activeJourney!.feedback = feedback;

    try {
      await apiService.completeJourney(
        journeyId: _activeJourney!.journeyId,
        completedStatus: 'completed',
        finalDistanceKm: _activeJourney!.distanceKm,
        routeExperience: routeExperience,
        issuesNoticed: issuesNoticed,
        comments: comments,
      );

      await FirebaseService.syncFeedback(
        journeyId: _activeJourney!.journeyId,
        userId: _activeJourney!.userId,
        feedback: feedback,
        routeId: _activeJourney!.selectedRoute.routeId,
        safetyScore: _activeJourney!.safetyScore,
        emergencyOccurred: _activeJourney!.emergencyOccurred,
      );
      await FirebaseService.syncJourney(_activeJourney!);

      _journeyHistory.removeWhere((j) => j.journeyId == _activeJourney!.journeyId);
      _journeyHistory.insert(0, _activeJourney!);
      // P5: Persist locally for offline access
      _localStore?.saveJourney(_activeJourney!);

      _isNavigating = false;
      _isDestinationReached = false;
      _emergencyActive = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[JourneyProvider] Submit report note: $e');
      if (_activeJourney != null) {
        _journeyHistory.removeWhere((j) => j.journeyId == _activeJourney!.journeyId);
        _journeyHistory.insert(0, _activeJourney!);
      // P5: Persist locally for offline access
      _localStore?.saveJourney(_activeJourney!);
      }
      _isNavigating = false;
      _isDestinationReached = false;
      _emergencyActive = false;
      notifyListeners();
      return true;
    }
  }

  // Skip feedback and conclude
  void skipFeedback() {
    stopLiveNavigation();

    if (_activeJourney != null) {
      _activeJourney!.endTime = DateTime.now();
      _activeJourney!.journeyStatus = 'completed';
      _journeyHistory.removeWhere((j) => j.journeyId == _activeJourney!.journeyId);
      _journeyHistory.insert(0, _activeJourney!);
      // P5: Persist locally for offline access
      _localStore?.saveJourney(_activeJourney!);
    }
    _isNavigating = false;
    _isDestinationReached = false;
    _emergencyActive = false;
    notifyListeners();
  }

  // 5. Fetch Real Stored Journey History
  Future<void> fetchJourneyHistory(String userId) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      List<ActiveJourney> list = [];
      if (FirebaseService.isAvailable) {
        list = await FirebaseService.getJourneysForUser(userId);
      }

      if (list.isEmpty) {
        try {
          list = await apiService.getUserJourneys(userId);
        } catch (_) {}
      }

      // P5: Supplement with locally-cached journeys if backend/Firebase returned nothing
      if (list.isEmpty) {
        try {
          final localStore = LocalJourneyStore(userId: userId);
          final localJourneys = await localStore.loadJourneys();
          list.addAll(localJourneys);
          debugPrint('[JourneyProvider] Loaded ${localJourneys.length} local journeys as fallback');
        } catch (_) {}
      }

      final existingIds = list.map((j) => j.journeyId).toSet();
      for (final j in _journeyHistory) {
        if (!existingIds.contains(j.journeyId)) {
          list.add(j);
        }
      }

      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      _journeyHistory = list;
    } catch (e) {
      debugPrint('[JourneyProvider] fetchJourneyHistory note: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
