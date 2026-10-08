import 'package:flutter/foundation.dart';
import '../models/route_model.dart';
import '../models/amenity_model.dart';
import '../services/api_service.dart';

class RouteProvider with ChangeNotifier {
  final ApiService apiService;

  RoutePlanResult? _planResult;
  EnrichedRoute? _selectedRoute;
  NearbySafeSpots? _nearbySafeSpots;
  bool _isLoadingRoutes = false;
  bool _isLoadingAmenities = false;
  String? _errorMessage;

  // Map Filter Toggles
  bool _showPolice = true;
  bool _showHospitals = true;
  bool _showTransit = true;
  bool _showBlackspots = true;

  RouteProvider({required this.apiService});

  RoutePlanResult? get planResult => _planResult;
  EnrichedRoute? get selectedRoute => _selectedRoute;
  NearbySafeSpots? get nearbySafeSpots => _nearbySafeSpots;
  bool get isLoadingRoutes => _isLoadingRoutes;
  bool get isLoadingAmenities => _isLoadingAmenities;
  String? get errorMessage => _errorMessage;

  bool get showPolice => _showPolice;
  bool get showHospitals => _showHospitals;
  bool get showTransit => _showTransit;
  bool get showBlackspots => _showBlackspots;

  void togglePolice() {
    _showPolice = !_showPolice;
    notifyListeners();
  }

  void toggleHospitals() {
    _showHospitals = !_showHospitals;
    notifyListeners();
  }

  void toggleTransit() {
    _showTransit = !_showTransit;
    notifyListeners();
  }

  void toggleBlackspots() {
    _showBlackspots = !_showBlackspots;
    notifyListeners();
  }

  void selectRoute(EnrichedRoute route) {
    _selectedRoute = route;
    notifyListeners();
  }

  Future<bool> planRoutes({
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    String travelMode = 'driving',
  }) async {
    _isLoadingRoutes = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiService.planRoutes(
        origin: origin,
        destination: destination,
        travelMode: travelMode,
        alternatives: true,
      );
      _planResult = res;

      // Default selection: recommend the safer route
      if (res.routes.isNotEmpty) {
        _selectedRoute = res.routes.firstWhere(
          (r) => r.isRecommendedSafer,
          orElse: () => res.routes.first,
        );
      }

      _isLoadingRoutes = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoadingRoutes = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchNearbyAmenities(double lat, double lon) async {
    _isLoadingAmenities = true;
    notifyListeners();

    try {
      final res = await apiService.getNearbySafeSpots(lat: lat, lon: lon, radiusKm: 5.0);
      _nearbySafeSpots = res;
    } catch (e) {
      debugPrint('Error fetching nearby safe spots: $e');
    } finally {
      _isLoadingAmenities = false;
      notifyListeners();
    }
  }

  void clearRoutes() {
    _planResult = null;
    _selectedRoute = null;
    notifyListeners();
  }
}
