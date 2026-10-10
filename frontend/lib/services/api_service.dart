import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/route_model.dart';
import '../models/amenity_model.dart';
import '../models/sos_model.dart';
import '../models/user_model.dart';
import '../models/journey_model.dart';
import '../models/navigation_model.dart';

class ApiService {
  String baseUrl;
  String? authToken;
  final Map<String, String> _reverseGeocodeCache = {};

  ApiService({this.baseUrl = AppConstants.defaultApiUrl});

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  // 1. Plan & Compare Routes
  Future<RoutePlanResult> planRoutes({
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    String travelMode = 'driving',
    bool alternatives = true,
  }) async {
    final payload = jsonEncode({
      'origin': origin,
      'destination': destination,
      'travel_mode': travelMode,
      'alternatives': alternatives,
    });

    try {
      final url = Uri.parse('$baseUrl/api/v1/routes/plan');
      final response = await http
          .post(url, headers: _headers(), body: payload)
          .timeout(const Duration(seconds: 18));

      if (response.statusCode == 200) {
        return RoutePlanResult.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Route planning failed: ${response.body}');
      }
    } on TimeoutException {
      // If primary IP timed out on emulator, attempt 10.0.2.2 fallback host
      if (baseUrl != 'http://10.0.2.2:8000') {
        try {
          final fallbackUrl = Uri.parse('http://10.0.2.2:8000/api/v1/routes/plan');
          final response = await http
              .post(fallbackUrl, headers: _headers(), body: payload)
              .timeout(const Duration(seconds: 12));
          if (response.statusCode == 200) {
            baseUrl = 'http://10.0.2.2:8000';
            return RoutePlanResult.fromJson(jsonDecode(response.body));
          }
        } catch (_) {}
      }
      throw Exception('Route calculation timed out. Please check your network connection and retry.');
    } catch (e) {
      // If host unreachable (e.g. SocketException), try 10.0.2.2 fallback host
      if (baseUrl != 'http://10.0.2.2:8000') {
        try {
          final fallbackUrl = Uri.parse('http://10.0.2.2:8000/api/v1/routes/plan');
          final response = await http
              .post(fallbackUrl, headers: _headers(), body: payload)
              .timeout(const Duration(seconds: 12));
          if (response.statusCode == 200) {
            baseUrl = 'http://10.0.2.2:8000';
            return RoutePlanResult.fromJson(jsonDecode(response.body));
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  // 1b. Real-Time Turn-By-Turn Navigation Route & Maneuvers
  Future<NavigationRoute> getNavigationRoute({
    required double originLat,
    required double originLon,
    required double destLat,
    required double destLon,
    String travelMode = 'driving',
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/navigation/route');
    final response = await http
        .post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'origin_lat': originLat,
            'origin_lon': originLon,
            'dest_lat': destLat,
            'dest_lon': destLon,
            'travel_mode': travelMode,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      return NavigationRoute.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Navigation routing failed: ${response.body}');
    }
  }

  // 2. Search Hyderabad Places & Landmarks
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final url = Uri.parse('$baseUrl/api/v1/places/autocomplete?q=${Uri.encodeComponent(query)}');
    final response = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  // 2b. Reverse Geocode Coordinates to Hyderabad Location Name
  Future<String> reverseGeocode(double lat, double lon) async {
    final cacheKey = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
    if (_reverseGeocodeCache.containsKey(cacheKey)) {
      return _reverseGeocodeCache[cacheKey]!;
    }

    try {
      final url = Uri.parse('$baseUrl/api/v1/places/reverse-geocode?lat=$lat&lon=$lon');
      final response = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addr = data['address'] as String?;
        if (addr != null && addr.isNotEmpty) {
          _reverseGeocodeCache[cacheKey] = addr;
          return addr;
        }
      }
    } catch (_) {
      // If primary host fails, try emulator host
      if (baseUrl != 'http://10.0.2.2:8000') {
        try {
          final fallbackUrl = Uri.parse('http://10.0.2.2:8000/api/v1/places/reverse-geocode?lat=$lat&lon=$lon');
          final response = await http.get(fallbackUrl, headers: _headers()).timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final addr = data['address'] as String?;
            if (addr != null && addr.isNotEmpty) {
              _reverseGeocodeCache[cacheKey] = addr;
              baseUrl = 'http://10.0.2.2:8000';
              return addr;
            }
          }
        } catch (_) {}
      }
    }

    final fallback = '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
    _reverseGeocodeCache[cacheKey] = fallback;
    return fallback;
  }

  // 3. Nearby Safe Spots (Police, Hospitals, Transit, Blackspots)
  Future<NearbySafeSpots> getNearbySafeSpots({
    required double lat,
    required double lon,
    double radiusKm = 5.0,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/safety/nearby-safe-spots?lat=$lat&lon=$lon&radius_km=$radiusKm');
    final response = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return NearbySafeSpots.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load nearby safe spots: ${response.body}');
    }
  }

  // 4. Trigger Emergency SOS
  Future<SOSResponse> triggerSOS({
    required double lat,
    required double lon,
    int? batteryLevel,
    String? message,
    String? currentRouteId,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/sos/trigger');
    final response = await http
        .post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'latitude': lat,
            'longitude': lon,
            'battery_level': batteryLevel,
            'message': message ?? 'EMERGENCY: Assistance needed at current coordinates.',
            'current_route_id': currentRouteId,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      return SOSResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('SOS distress signal failed: ${response.body}');
    }
  }

  // 5. Trusted Emergency Contacts
  Future<List<TrustedContact>> getContacts({String userId = 'anonymous_user'}) async {
    final url = Uri.parse('$baseUrl/api/v1/user/contacts?user_id=$userId');
    final response = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => TrustedContact.fromJson(e)).toList();
    }
    return [];
  }

  Future<TrustedContact> addContact(TrustedContact contact, {String userId = 'anonymous_user'}) async {
    final url = Uri.parse('$baseUrl/api/v1/user/contacts?user_id=$userId');
    final response = await http
        .post(url, headers: _headers(), body: jsonEncode(contact.toJson()))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 201) {
      return TrustedContact.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add contact');
    }
  }

  Future<TrustedContact> updateContact(
    String contactId,
    TrustedContact contact, {
    String userId = 'anonymous_user',
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/user/contacts/$contactId?user_id=$userId');
    final response = await http
        .put(url, headers: _headers(), body: jsonEncode(contact.toJson()))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      return TrustedContact.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update contact');
    }
  }

  Future<bool> deleteContact(
    String contactId, {
    String userId = 'anonymous_user',
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/user/contacts/$contactId?user_id=$userId');
    final response = await http
        .delete(url, headers: _headers())
        .timeout(const Duration(seconds: 8));

    return response.statusCode == 200;
  }

  // 6. User Authentication
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/register');
    final response = await http
        .post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'email': email,
            'password': password,
            'full_name': fullName,
            'phone': phone,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final result = AuthResult.fromJson(jsonDecode(response.body));
      authToken = result.accessToken;
      return result;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/login');
    final response = await http
        .post(url, headers: _headers(), body: jsonEncode({'email': email, 'password': password}))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final result = AuthResult.fromJson(jsonDecode(response.body));
      authToken = result.accessToken;
      return result;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<AuthResult> authenticateFirebase(String idToken) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/firebase');
    final response = await http
        .post(url, headers: _headers(), body: jsonEncode({'id_token': idToken}))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final result = AuthResult.fromJson(jsonDecode(response.body));
      authToken = result.accessToken;
      return result;
    } else {
      throw Exception('Firebase auth exchange failed: ${response.body}');
    }
  }

  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/user/profile');
    final response = await http
        .put(
          url,
          headers: _headers(),
          body: jsonEncode({
            'user_id': userId,
            'full_name': fullName,
            'phone': phone,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // 7. Journey Navigation & Feedback Pipeline
  Future<Map<String, dynamic>> startJourney({
    required String userId,
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    required EnrichedRoute route,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/journey/start');
    final response = await http
        .post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'user_id': userId,
            'origin': origin,
            'destination': destination,
            'selected_route_id': route.routeId,
            'route_summary': route.summary,
            'distance_km': route.distanceKm,
            'duration_min': route.durationMin,
            'safety_score': route.safetyScore,
            'safety_tier': route.safetyTier,
            'is_recommended_safer': route.isRecommendedSafer,
            'polyline_coords': route.polylineCoords.map((c) => {'latitude': c.latitude, 'longitude': c.longitude}).toList(),
            'contributions': {
              'police_pts': route.contributions.policePts,
              'medical_pts': route.contributions.medicalPts,
              'transit_pts': route.contributions.transitPts,
              'arterial_pts': route.contributions.arterialPts,
              'crime_compliance_pts': route.contributions.crimeCompliancePts,
              'blackspot_compliance_pts': route.contributions.blackspotCompliancePts,
              'exposure_compliance_pts': route.contributions.exposureCompliancePts,
            },
            'raw_features': {
              'avg_police_dist_km': route.rawFeatures.avgPoliceDistKm,
              'police_within_1km_count': route.rawFeatures.policeWithin1kmCount,
              'min_hospital_dist_km': route.rawFeatures.minHospitalDistKm,
              'transit_count_within_500m': route.rawFeatures.transitCountWithin500m,
              'arterial_length_km': route.rawFeatures.arterialLengthKm,
              'traversed_zones': route.rawFeatures.traversedZones,
              'blackspot_count': route.rawFeatures.blackspotCount,
            },
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to start journey: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> recordJourneyEvent({
    required String journeyId,
    required String eventType,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? details,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/journey/event');
    final response = await http
        .post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'journey_id': journeyId,
            'event_type': eventType,
            'latitude': latitude,
            'longitude': longitude,
            'details': details,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to record journey event: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> completeJourney({
    required String journeyId,
    String completedStatus = 'completed',
    double? finalDistanceKm,
    String? routeExperience,
    List<String>? issuesNoticed,
    String? comments,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/journey/complete');
    final response = await http
        .post(
          url,
          headers: _headers(),
          body: jsonEncode({
            'journey_id': journeyId,
            'completed_status': completedStatus,
            'final_distance_km': finalDistanceKm,
            'route_experience': routeExperience,
            'issues_noticed': issuesNoticed,
            'comments': comments,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to complete journey: ${response.body}');
    }
  }

  Future<List<ActiveJourney>> getUserJourneys(String userId) async {
    final url = Uri.parse('$baseUrl/api/v1/journey/user?user_id=$userId');
    final response = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => ActiveJourney.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }
}
