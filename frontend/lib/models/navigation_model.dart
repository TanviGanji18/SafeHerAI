import 'package:flutter/material.dart';
import 'package:safeher_ai/models/route_model.dart';

class NavigationStep {
  final int stepIndex;
  final String instruction;
  final String maneuverType;
  final String? modifier;
  final String roadName;
  final double distanceMeters;
  final double durationSeconds;
  final double latitude;
  final double longitude;
  final double? bearing;

  NavigationStep({
    required this.stepIndex,
    required this.instruction,
    this.maneuverType = 'turn',
    this.modifier,
    this.roadName = '',
    this.distanceMeters = 0.0,
    this.durationSeconds = 0.0,
    required this.latitude,
    required this.longitude,
    this.bearing,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    return NavigationStep(
      stepIndex: (json['step_index'] as num?)?.toInt() ?? 0,
      instruction: json['instruction'] as String? ?? 'Continue',
      maneuverType: json['maneuver_type'] as String? ?? 'turn',
      modifier: json['modifier'] as String?,
      roadName: json['road_name'] as String? ?? '',
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      bearing: (json['bearing'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_index': stepIndex,
      'instruction': instruction,
      'maneuver_type': maneuverType,
      'modifier': modifier,
      'road_name': roadName,
      'distance_meters': distanceMeters,
      'duration_seconds': durationSeconds,
      'latitude': latitude,
      'longitude': longitude,
      'bearing': bearing,
    };
  }

  IconData get icon {
    final type = maneuverType.toLowerCase();
    final mod = (modifier ?? '').toLowerCase();

    if (type == 'depart') return Icons.navigation_rounded;
    if (type == 'arrive') return Icons.flag_circle_rounded;
    if (type == 'roundabout') return Icons.roundabout_right_rounded;

    if (mod.contains('uturn')) return Icons.u_turn_left_rounded;
    if (mod.contains('slight') && mod.contains('left')) return Icons.turn_slight_left_rounded;
    if (mod.contains('slight') && mod.contains('right')) return Icons.turn_slight_right_rounded;
    if (mod.contains('left')) return Icons.turn_left_rounded;
    if (mod.contains('right')) return Icons.turn_right_rounded;
    if (mod.contains('straight')) return Icons.straight_rounded;

    return Icons.navigation_rounded;
  }
}

class NavigationRoute {
  final double distanceKm;
  final double durationMin;
  final List<CoordinatePoint> polylineCoords;
  final List<NavigationStep> steps;
  final String summary;

  NavigationRoute({
    required this.distanceKm,
    required this.durationMin,
    required this.polylineCoords,
    required this.steps,
    required this.summary,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    return NavigationRoute(
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMin: (json['duration_min'] as num?)?.toDouble() ?? 0.0,
      polylineCoords: (json['polyline_coords'] as List<dynamic>?)
              ?.map((pt) => CoordinatePoint.fromJson(pt as Map<String, dynamic>))
              .toList() ??
          [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => NavigationStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String? ?? 'Navigation corridor',
    );
  }
}
