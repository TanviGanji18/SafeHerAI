import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_model.dart';
import '../models/journey_model.dart';
import '../models/sos_model.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class JourneyProvider with ChangeNotifier {
  final ApiService apiService;

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
  int _currentPolylineIndex = 0;
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
  List<ActiveJourney> get journeyHistory => _journeyHistory;
  bool get isLoadingHistory => _isLoadingHistory;

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
    _currentPolylineIndex = 0;

    if (actualRoute.polylineCoords.isNotEmpty) {
      _currentLocation = LatLng(
        actualRoute.polylineCoords.first.latitude,
        actualRoute.polylineCoords.first.longitude,
      );
      _destinationLocation = LatLng(
        actualRoute.polylineCoords.last.latitude,
        actualRoute.polylineCoords.last.longitude,
      );
    }

    _updateInstruction(actualRoute);
    notifyListeners();

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
      // Local navigation continues even if server endpoint takes longer
      return true;
    }
  }

  void _updateInstruction(EnrichedRoute route) {
    if (route.isRecommendedSafer) {
      _currentInstruction = 'Navigating on Safer Route • High Police & Transit Density';
    } else if (route.isFastest) {
      _currentInstruction = 'Navigating on Fastest Route • Maintaining Speed';
    } else {
      _currentInstruction = 'Navigating on Alternative Corridor';
    }
  }

  // 2. Location Tracking & Destination Arrival Detection
  void updateLocation(LatLng newLocation) {
    _currentLocation = newLocation;

    if (_destinationLocation != null) {
      final distToDest = _calculateDistanceKm(newLocation, _destinationLocation!);
      _remainingDistanceKm = distToDest;
      if (_activeJourney != null && _activeJourney!.distanceKm > 0) {
        final progressRatio = 1.0 - (distToDest / _activeJourney!.distanceKm).clamp(0.0, 1.0);
        _remainingDurationMin = (_activeJourney!.durationMin * (1.0 - progressRatio)).clamp(0.0, _activeJourney!.durationMin);
      }

      // Arrival threshold: within 75 meters (0.075 km)
      if (distToDest <= 0.075 && !_isDestinationReached) {
        _isDestinationReached = true;
        _currentInstruction = 'Destination Reached!';
      }
    }
    notifyListeners();
  }

  // Advance navigation along route for smooth testing/demo on emulators
  void advanceAlongRoute() {
    if (_activeJourney == null || _activeJourney!.selectedRoute.polylineCoords.isEmpty) return;
    final coords = _activeJourney!.selectedRoute.polylineCoords;

    if (_currentPolylineIndex < coords.length - 1) {
      _currentPolylineIndex++;
      final target = coords[_currentPolylineIndex];
      updateLocation(LatLng(target.latitude, target.longitude));
    } else {
      _isDestinationReached = true;
      _currentInstruction = 'Destination Reached!';
      notifyListeners();
    }
  }

  // Manual End / Destination Arrival Trigger
  void triggerDestinationReached() {
    _isDestinationReached = true;
    _currentInstruction = 'Destination Reached!';
    notifyListeners();
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

    // Record Event locally
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
      // 1. Log event with Journey Service
      await apiService.recordJourneyEvent(
        journeyId: jId,
        eventType: 'sos_trigger',
        latitude: lat,
        longitude: lon,
        details: {'battery': batteryLevel, 'message': message},
      );

      // 2. Trigger SOS dispatch on Backend
      final sosRes = await apiService.triggerSOS(
        lat: lat,
        lon: lon,
        batteryLevel: batteryLevel,
        message: message ?? 'EMERGENCY: Immediate safety assistance requested during journey.',
        currentRouteId: _activeJourney?.selectedRoute.routeId,
      );
      _lastSOSResponse = sosRes;

      // 3. Sync to Cloud Firestore
      await FirebaseService.syncSOSEvent(
        journeyId: jId,
        userId: _activeJourney?.userId ?? 'anonymous_user',
        lat: lat,
        lon: lon,
        timestamp: DateTime.now(),
        metadata: {'alert_id': sosRes.alertId, 'nearest_police': sosRes.nearestPoliceStation.name},
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
      // 1. Submit to Backend for future model learning dataset
      await apiService.completeJourney(
        journeyId: _activeJourney!.journeyId,
        completedStatus: 'completed',
        finalDistanceKm: _activeJourney!.distanceKm,
        routeExperience: routeExperience,
        issuesNoticed: issuesNoticed,
        comments: comments,
      );

      // 2. Sync to Cloud Firestore
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
    if (_activeJourney != null) {
      _activeJourney!.endTime = DateTime.now();
      _activeJourney!.journeyStatus = 'completed';
      _journeyHistory.removeWhere((j) => j.journeyId == _activeJourney!.journeyId);
      _journeyHistory.insert(0, _activeJourney!);
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
      // 1. Check Cloud Firestore if available
      if (FirebaseService.isAvailable) {
        list = await FirebaseService.getJourneysForUser(userId);
      }

      // 2. Query backend journey storage if Firestore list is empty or offline
      if (list.isEmpty) {
        try {
          list = await apiService.getUserJourneys(userId);
        } catch (_) {}
      }

      // 3. Preserve session-completed journeys
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
}
