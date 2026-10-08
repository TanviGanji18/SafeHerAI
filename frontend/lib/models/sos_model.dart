import 'route_model.dart';
import 'amenity_model.dart';

class TrustedContact {
  final String? id;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;

  TrustedContact({
    this.id,
    required this.name,
    required this.phone,
    this.relationship = 'Family',
    this.isPrimary = false,
  });

  factory TrustedContact.fromJson(Map<String, dynamic> json) {
    return TrustedContact(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? 'Family',
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'phone': phone,
    'relationship': relationship,
    'is_primary': isPrimary,
  };
}

class SOSResponse {
  final String alertId;
  final String status;
  final String timestamp;
  final CoordinatePoint userLocation;
  final String mapsLocationUrl;
  final AmenityItem nearestPoliceStation;
  final int dispatchedContactsCount;
  final List<String> contactsNotified;
  final Map<String, dynamic> emergencyHelplines;
  final List<String> safetyGuidance;

  SOSResponse({
    required this.alertId,
    required this.status,
    required this.timestamp,
    required this.userLocation,
    required this.mapsLocationUrl,
    required this.nearestPoliceStation,
    required this.dispatchedContactsCount,
    required this.contactsNotified,
    required this.emergencyHelplines,
    required this.safetyGuidance,
  });

  factory SOSResponse.fromJson(Map<String, dynamic> json) {
    return SOSResponse(
      alertId: json['alert_id'] ?? '',
      status: json['status'] ?? '',
      timestamp: json['timestamp'] ?? '',
      userLocation: CoordinatePoint.fromJson(json['user_location']),
      mapsLocationUrl: json['maps_location_url'] ?? '',
      nearestPoliceStation: AmenityItem.fromJson(json['nearest_police_station']),
      dispatchedContactsCount: json['dispatched_contacts_count'] ?? 0,
      contactsNotified: (json['contacts_notified'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      emergencyHelplines: json['emergency_helplines'] ?? {},
      safetyGuidance: (json['safety_guidance'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
