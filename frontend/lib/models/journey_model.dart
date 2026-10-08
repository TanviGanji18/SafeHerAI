import 'route_model.dart';

class JourneyFeedback {
  final String routeExperience; // 'Comfortable', 'Average', 'Felt Unsafe'
  final List<String> issuesNoticed;
  final String? comments;
  final DateTime submittedAt;

  JourneyFeedback({
    required this.routeExperience,
    required this.issuesNoticed,
    this.comments,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
    'route_experience': routeExperience,
    'issues_noticed': issuesNoticed,
    'comments': comments,
    'submitted_at': submittedAt.toIso8601String(),
  };

  factory JourneyFeedback.fromJson(Map<String, dynamic> json) => JourneyFeedback(
    routeExperience: json['route_experience'] ?? 'Average',
    issuesNoticed: (json['issues_noticed'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    comments: json['comments'],
    submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : DateTime.now(),
  );
}

class JourneyEvent {
  final String eventType; // 'sos_trigger', 'waypoint_reached', 'route_deviation'
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  JourneyEvent({
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };

  factory JourneyEvent.fromJson(Map<String, dynamic> json) => JourneyEvent(
    eventType: json['event_type'] ?? 'event',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    timestamp: json['timestamp'] != null
        ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
        : DateTime.now(),
    details: json['details'] != null ? Map<String, dynamic>.from(json['details']) : null,
  );
}

class ActiveJourney {
  final String journeyId;
  final String userId;
  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;
  final EnrichedRoute selectedRoute;
  final double distanceKm;
  final double durationMin;
  final double safetyScore;
  final DateTime startTime;
  DateTime? endTime;
  String journeyStatus; // 'active', 'completed', 'emergency_ended', 'cancelled'
  bool emergencyOccurred;
  final List<JourneyEvent> sosEvents;
  JourneyFeedback? feedback;

  ActiveJourney({
    required this.journeyId,
    required this.userId,
    required this.origin,
    required this.destination,
    required this.selectedRoute,
    required this.distanceKm,
    required this.durationMin,
    required this.safetyScore,
    required this.startTime,
    this.endTime,
    this.journeyStatus = 'active',
    this.emergencyOccurred = false,
    List<JourneyEvent>? sosEvents,
    this.feedback,
  }) : sosEvents = sosEvents ?? [];

  String get routeSummary => selectedRoute.summary;
  String get safetyTier => selectedRoute.safetyTier;
  String get originAddress => origin['address'] ?? origin['name'] ?? 'Origin';
  String get destinationAddress => destination['address'] ?? destination['name'] ?? 'Destination';

  Map<String, dynamic> toJson() => {
    'journey_id': journeyId,
    'user_id': userId,
    'origin': origin,
    'destination': destination,
    'selected_route_id': selectedRoute.routeId,
    'route_summary': selectedRoute.summary,
    'distance_km': distanceKm,
    'duration_min': durationMin,
    'safety_score': safetyScore,
    'safety_tier': selectedRoute.safetyTier,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'journey_status': journeyStatus,
    'emergency_occurred': emergencyOccurred,
    'sos_events': sosEvents.map((e) => e.toJson()).toList(),
    'feedback': feedback?.toJson(),
  };

  static EnrichedRoute _createDefaultRoute(Map<String, dynamic> json) {
    final score = (json['safety_score'] as num?)?.toDouble() ?? 75.0;
    final dist = (json['distance_km'] as num?)?.toDouble() ?? 0.0;
    final dur = (json['duration_min'] as num?)?.toDouble() ?? 0.0;
    final summary = json['route_summary']?.toString() ?? 'Safer Urban Corridor';
    final tier = json['safety_tier']?.toString() ?? 'High Safety Corridor';
    final routeId = json['selected_route_id']?.toString() ?? 'route_1';

    return EnrichedRoute(
      routeId: routeId,
      summary: summary,
      safetyScore: score,
      safetyTier: tier,
      isRecommendedSafer: true,
      isFastest: false,
      distanceKm: dist,
      durationMin: dur,
      polylineCoords: [],
      components: ComponentScores(
        sPolice: 0.8,
        sMedical: 0.8,
        sTransit: 0.8,
        sArterial: 0.8,
        pCrime: 0.2,
        pBlackspot: 0.1,
        pExposure: 0.1,
      ),
      contributions: ComponentContributions(
        policePts: (score * 0.25).clamp(0.0, 25.0),
        medicalPts: (score * 0.15).clamp(0.0, 15.0),
        transitPts: (score * 0.15).clamp(0.0, 15.0),
        arterialPts: (score * 0.15).clamp(0.0, 15.0),
        crimeCompliancePts: (score * 0.15).clamp(0.0, 15.0),
        blackspotCompliancePts: (score * 0.10).clamp(0.0, 10.0),
        exposureCompliancePts: (score * 0.05).clamp(0.0, 5.0),
      ),
      rawFeatures: RawFeatures(
        avgPoliceDistKm: 1.2,
        policeWithin1kmCount: 2,
        minHospitalDistKm: 1.5,
        transitCountWithin500m: 4,
        arterialLengthKm: dist,
        traversedZones: ['Central', 'West'],
        blackspotCount: 0,
      ),
    );
  }

  factory ActiveJourney.fromJson(Map<String, dynamic> json) {
    EnrichedRoute route;
    if (json['selected_route'] != null && json['selected_route'] is Map) {
      try {
        route = EnrichedRoute.fromJson(Map<String, dynamic>.from(json['selected_route']));
      } catch (_) {
        route = _createDefaultRoute(json);
      }
    } else {
      route = _createDefaultRoute(json);
    }

    final rawSos = json['sos_events'];
    List<JourneyEvent> events = [];
    if (rawSos is List) {
      events = rawSos
          .whereType<Map>()
          .map((e) => JourneyEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    JourneyFeedback? fb;
    if (json['feedback'] != null && json['feedback'] is Map) {
      try {
        fb = JourneyFeedback.fromJson(Map<String, dynamic>.from(json['feedback']));
      } catch (_) {}
    }

    return ActiveJourney(
      journeyId: json['journey_id'] ?? '',
      userId: json['user_id'] ?? '',
      origin: json['origin'] != null ? Map<String, dynamic>.from(json['origin']) : {'address': 'Origin'},
      destination: json['destination'] != null ? Map<String, dynamic>.from(json['destination']) : {'address': 'Destination'},
      selectedRoute: route,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? route.distanceKm,
      durationMin: (json['duration_min'] as num?)?.toDouble() ?? route.durationMin,
      safetyScore: (json['safety_score'] as num?)?.toDouble() ?? route.safetyScore,
      startTime: json['start_time'] != null
          ? (DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now())
          : DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time'].toString()) : null,
      journeyStatus: json['journey_status'] ?? json['status'] ?? 'completed',
      emergencyOccurred: json['emergency_occurred'] == true,
      sosEvents: events,
      feedback: fb,
    );
  }
}
