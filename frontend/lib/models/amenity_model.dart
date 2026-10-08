import 'route_model.dart';

class AmenityItem {
  final String id;
  final String name;
  final String category;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? zoneOrCircle;
  final String? extraDetails;

  AmenityItem({
    required this.id,
    required this.name,
    required this.category,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.zoneOrCircle,
    this.extraDetails,
  });

  factory AmenityItem.fromJson(Map<String, dynamic> json) {
    return AmenityItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Amenity',
      distanceKm: (json['distance_km'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'],
      zoneOrCircle: json['zone_or_circle'],
      extraDetails: json['extra_details'],
    );
  }
}

class NearbySafeSpots {
  final CoordinatePoint userLocation;
  final double radiusKm;
  final List<AmenityItem> policeStations;
  final List<AmenityItem> hospitals;
  final List<AmenityItem> transitStations;
  final List<AmenityItem> accidentBlackspots;
  final Map<String, dynamic> emergencyHelplines;

  NearbySafeSpots({
    required this.userLocation,
    required this.radiusKm,
    required this.policeStations,
    required this.hospitals,
    required this.transitStations,
    required this.accidentBlackspots,
    required this.emergencyHelplines,
  });

  factory NearbySafeSpots.fromJson(Map<String, dynamic> json) {
    return NearbySafeSpots(
      userLocation: CoordinatePoint.fromJson(json['user_location']),
      radiusKm: (json['radius_km'] as num).toDouble(),
      policeStations: (json['police_stations'] as List<dynamic>?)
              ?.map((e) => AmenityItem.fromJson(e))
              .toList() ??
          [],
      hospitals: (json['hospitals'] as List<dynamic>?)
              ?.map((e) => AmenityItem.fromJson(e))
              .toList() ??
          [],
      transitStations: (json['transit_stations'] as List<dynamic>?)
              ?.map((e) => AmenityItem.fromJson(e))
              .toList() ??
          [],
      accidentBlackspots: (json['accident_blackspots'] as List<dynamic>?)
              ?.map((e) => AmenityItem.fromJson(e))
              .toList() ??
          [],
      emergencyHelplines: json['emergency_helplines'] ?? {},
    );
  }
}
