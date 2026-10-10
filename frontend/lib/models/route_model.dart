import 'package:safeher_ai/models/navigation_model.dart';

class CoordinatePoint {
  final double latitude;
  final double longitude;

  CoordinatePoint({required this.latitude, required this.longitude});

  factory CoordinatePoint.fromJson(Map<String, dynamic> json) {
    return CoordinatePoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class ComponentScores {
  final double sPolice;
  final double sMedical;
  final double sTransit;
  final double sArterial;
  final double pCrime;
  final double pBlackspot;
  final double pExposure;

  ComponentScores({
    required this.sPolice,
    required this.sMedical,
    required this.sTransit,
    required this.sArterial,
    required this.pCrime,
    required this.pBlackspot,
    required this.pExposure,
  });

  factory ComponentScores.fromJson(Map<String, dynamic> json) {
    return ComponentScores(
      sPolice: (json['S_police'] as num?)?.toDouble() ?? 75.0,
      sMedical: (json['S_medical'] as num?)?.toDouble() ?? 75.0,
      sTransit: (json['S_transit'] as num?)?.toDouble() ?? 75.0,
      sArterial: (json['S_arterial'] as num?)?.toDouble() ?? 75.0,
      pCrime: (json['P_crime'] as num?)?.toDouble() ?? 75.0,
      pBlackspot: (json['P_blackspot'] as num?)?.toDouble() ?? 75.0,
      pExposure: (json['P_exposure'] as num?)?.toDouble() ?? 75.0,
    );
  }
}

class ComponentContributions {
  final double policePts;
  final double medicalPts;
  final double transitPts;
  final double arterialPts;
  final double crimeCompliancePts;
  final double blackspotCompliancePts;
  final double exposureCompliancePts;

  ComponentContributions({
    required this.policePts,
    required this.medicalPts,
    required this.transitPts,
    required this.arterialPts,
    required this.crimeCompliancePts,
    required this.blackspotCompliancePts,
    required this.exposureCompliancePts,
  });

  factory ComponentContributions.fromJson(Map<String, dynamic> json) {
    return ComponentContributions(
      policePts: (json['police_pts'] as num?)?.toDouble() ?? 0.0,
      medicalPts: (json['medical_pts'] as num?)?.toDouble() ?? 0.0,
      transitPts: (json['transit_pts'] as num?)?.toDouble() ?? 0.0,
      arterialPts: (json['arterial_pts'] as num?)?.toDouble() ?? 0.0,
      crimeCompliancePts: (json['crime_compliance_pts'] as num?)?.toDouble() ?? 0.0,
      blackspotCompliancePts: (json['blackspot_compliance_pts'] as num?)?.toDouble() ?? 0.0,
      exposureCompliancePts: (json['exposure_compliance_pts'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RawFeatures {
  final double avgPoliceDistKm;
  final int policeWithin1kmCount;
  final double minHospitalDistKm;
  final int transitCountWithin500m;
  final double arterialLengthKm;
  final List<String> traversedZones;
  final int blackspotCount;

  RawFeatures({
    required this.avgPoliceDistKm,
    required this.policeWithin1kmCount,
    required this.minHospitalDistKm,
    required this.transitCountWithin500m,
    required this.arterialLengthKm,
    required this.traversedZones,
    required this.blackspotCount,
  });

  factory RawFeatures.fromJson(Map<String, dynamic> json) {
    return RawFeatures(
      avgPoliceDistKm: (json['avg_police_dist_km'] as num).toDouble(),
      policeWithin1kmCount: (json['police_within_1km_count'] as num).toInt(),
      minHospitalDistKm: (json['min_hospital_dist_km'] as num).toDouble(),
      transitCountWithin500m: (json['transit_count_within_500m'] as num).toInt(),
      arterialLengthKm: (json['arterial_length_km'] as num).toDouble(),
      traversedZones: (json['traversed_zones'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      blackspotCount: (json['blackspot_count'] as num).toInt(),
    );
  }
}

class EnrichedRoute {
  final String routeId;
  final String summary;
  final double safetyScore;
  final String safetyTier;
  final bool isRecommendedSafer;
  final bool isFastest;
  final double distanceKm;
  final double durationMin;
  final List<CoordinatePoint> polylineCoords;
  final String? encodedPolyline;
  final ComponentScores components;
  final ComponentContributions contributions;
  final RawFeatures rawFeatures;
  final List<NavigationStep> steps;

  EnrichedRoute({
    required this.routeId,
    required this.summary,
    required this.safetyScore,
    required this.safetyTier,
    required this.isRecommendedSafer,
    required this.isFastest,
    required this.distanceKm,
    required this.durationMin,
    required this.polylineCoords,
    this.encodedPolyline,
    required this.components,
    required this.contributions,
    required this.rawFeatures,
    this.steps = const [],
  });

  factory EnrichedRoute.fromJson(Map<String, dynamic> json) {
    return EnrichedRoute(
      routeId: json['route_id'] ?? 'route_1',
      summary: json['summary'] ?? 'Urban corridor',
      safetyScore: (json['safety_score'] as num).toDouble(),
      safetyTier: json['safety_tier'] ?? 'Moderate Safety Corridor',
      isRecommendedSafer: json['is_recommended_safer'] ?? false,
      isFastest: json['is_fastest'] ?? false,
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationMin: (json['duration_min'] as num).toDouble(),
      polylineCoords: (json['polyline_coords'] as List<dynamic>?)
              ?.map((e) => CoordinatePoint.fromJson(e))
              .toList() ??
          [],
      encodedPolyline: json['encoded_polyline'],
      components: ComponentScores.fromJson(json['components']),
      contributions: ComponentContributions.fromJson(json['contributions']),
      rawFeatures: RawFeatures.fromJson(json['raw_features']),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => NavigationStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class RoutePlanResult {
  final CoordinatePoint origin;
  final CoordinatePoint destination;
  final String? originName;
  final String? destinationName;
  final String recommendedSaferRouteId;
  final String fastestRouteId;
  final bool isSaferDifferentFromFastest;
  final List<String> comparativeRationale;
  final List<EnrichedRoute> routes;
  final List<String> limitationsAndProxies;

  RoutePlanResult({
    required this.origin,
    required this.destination,
    this.originName,
    this.destinationName,
    required this.recommendedSaferRouteId,
    required this.fastestRouteId,
    required this.isSaferDifferentFromFastest,
    required this.comparativeRationale,
    required this.routes,
    required this.limitationsAndProxies,
  });

  factory RoutePlanResult.fromJson(Map<String, dynamic> json) {
    return RoutePlanResult(
      origin: CoordinatePoint.fromJson(json['origin']),
      destination: CoordinatePoint.fromJson(json['destination']),
      originName: json['origin_name'],
      destinationName: json['destination_name'],
      recommendedSaferRouteId: json['recommended_safer_route_id'] ?? '',
      fastestRouteId: json['fastest_route_id'] ?? '',
      isSaferDifferentFromFastest: json['is_safer_different_from_fastest'] ?? false,
      comparativeRationale: (json['comparative_rationale'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      routes: (json['routes'] as List<dynamic>?)?.map((e) => EnrichedRoute.fromJson(e)).toList() ?? [],
      limitationsAndProxies: (json['limitations_and_proxies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
