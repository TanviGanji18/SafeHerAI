import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/route_provider.dart';
import 'route_comparison_screen.dart';

class RoutePlanningScreen extends StatefulWidget {
  const RoutePlanningScreen({Key? key}) : super(key: key);

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen> {
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;
  String _travelMode = 'driving';
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _isLocatingOrigin = false;

  Map<String, dynamic>? _selectedOriginCoords;
  Map<String, dynamic>? _selectedDestCoords;

  StreamSubscription<Position>? _positionSubscription;
  Position? _lastResolvedPosition;
  DateTime? _lastReverseGeocodeTime;
  bool _userManuallyEditedOrigin = false;

  final List<Map<String, String>> _quickCorridors = [
    {'origin': 'Secunderabad Railway Station', 'destination': 'Charminar, Old City'},
    {'origin': 'Gachibowli Junction', 'destination': 'Begumpet Airport / Station'},
    {'origin': 'Hitec City / Cyber Towers, Madhapur', 'destination': 'Banjara Hills Road No. 1'},
    {'origin': 'Kukatpally Y-Junction', 'destination': 'Lakdikapul Metro Station'},
  ];

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController();
    _destinationController = TextEditingController();
    _originController.addListener(_onTextChanged);
    _destinationController.addListener(_onTextChanged);

    // Automatically obtain current GPS position and initiate live location tracking on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLiveLocationTracking();
    });
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _originController.removeListener(_onTextChanged);
    _destinationController.removeListener(_onTextChanged);
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _startLiveLocationTracking() async {
    await _handleUseCurrentLocation(isAutoStart: true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

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
          _onLivePositionUpdate(pos);
        },
        onError: (err) {
          debugPrint('[RoutePlanning] Position stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('[RoutePlanning] Location tracking stream init note: $e');
    }
  }

  void _onLivePositionUpdate(Position position) async {
    // If the user manually typed or searched a custom starting location, do not overwrite their input
    if (_userManuallyEditedOrigin) return;

    // Preserve exact real-time coordinates internally for routing
    _selectedOriginCoords = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': _originController.text.isNotEmpty ? _originController.text : 'Current Location',
    };

    // Calculate distance moved from last reverse-geocoded location
    double distMovedMeters = 999.0;
    if (_lastResolvedPosition != null) {
      distMovedMeters = Geolocator.distanceBetween(
        _lastResolvedPosition!.latitude,
        _lastResolvedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    // Refresh readable address when device moves meaningfully (> 20 meters) with 3s throttling
    final now = DateTime.now();
    final timeSinceLastSec = _lastReverseGeocodeTime == null
        ? 999
        : now.difference(_lastReverseGeocodeTime!).inSeconds;

    if (distMovedMeters >= 20.0 && timeSinceLastSec >= 3) {
      _lastReverseGeocodeTime = now;
      _lastResolvedPosition = position;
      try {
        final routeProv = Provider.of<RouteProvider>(context, listen: false);
        final address = await routeProv.apiService.reverseGeocode(position.latitude, position.longitude);
        if (mounted && !_userManuallyEditedOrigin) {
          setState(() {
            _originController.text = address;
            _selectedOriginCoords = {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'address': address,
            };
          });
        }
      } catch (e) {
        debugPrint('[RoutePlanning] Live address update note: $e');
      }
    }
  }

  Future<void> _handleUseCurrentLocation({bool isAutoStart = false}) async {
    if (!isAutoStart) {
      _userManuallyEditedOrigin = false;
    }
    setState(() => _isLocatingOrigin = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && !isAutoStart) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services (GPS) are disabled. Please enable GPS in device settings.'),
              backgroundColor: AppColors.emergencyRed,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLocatingOrigin = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted && !isAutoStart) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission was denied. You can still type your starting location manually.'),
              backgroundColor: AppColors.warningAmber,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLocatingOrigin = false);
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        throw Exception('Unable to acquire GPS fix. Please ensure location is enabled.');
      }

      _lastResolvedPosition = position;
      _lastReverseGeocodeTime = DateTime.now();

      final routeProv = Provider.of<RouteProvider>(context, listen: false);
      final address = await routeProv.apiService.reverseGeocode(position.latitude, position.longitude);

      if (mounted) {
        final fix = position;
        setState(() {
          _originController.text = address;
          _selectedOriginCoords = {
            'latitude': fix.latitude,
            'longitude': fix.longitude,
            'address': address,
          };
          _isLocatingOrigin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (!isAutoStart) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not determine current location: $e. Please type manually.'),
              backgroundColor: AppColors.emergencyRed,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLocatingOrigin = false);
      }
    }
  }

  void _onSearchDestination(String query) async {
    if (query.trim().length < 2) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = []);
      }
      return;
    }
    setState(() => _isSearching = true);
    final routeProv = Provider.of<RouteProvider>(context, listen: false);
    final results = await routeProv.apiService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    }
  }

  void _handlePlanRoutes() async {
    final originText = _originController.text.trim();
    final destinationText = _destinationController.text.trim();

    if (originText.isEmpty || destinationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            originText.isEmpty && destinationText.isEmpty
                ? 'Please enter both starting location and destination.'
                : originText.isEmpty
                    ? 'Please enter a starting location.'
                    : 'Please enter a destination.',
          ),
          backgroundColor: AppColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Pass resolved coordinates if available, otherwise pass address query
    final Map<String, dynamic> originPayload = _selectedOriginCoords != null &&
            _originController.text.trim() == (_selectedOriginCoords!['address'] ?? '')
        ? _selectedOriginCoords!
        : {'address': originText};

    final Map<String, dynamic> destPayload = _selectedDestCoords != null &&
            _destinationController.text.trim() == (_selectedDestCoords!['address'] ?? '')
        ? _selectedDestCoords!
        : {'address': destinationText};

    final routeProv = Provider.of<RouteProvider>(context, listen: false);
    final success = await routeProv.planRoutes(
      origin: originPayload,
      destination: destPayload,
      travelMode: _travelMode,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RouteComparisonScreen()),
      );
    } else if (!success && mounted && routeProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(routeProv.errorMessage!),
          backgroundColor: AppColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProv = Provider.of<RouteProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Safer Routes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Inputs Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Origin Input
                      TextField(
                        controller: _originController,
                        onChanged: (_) {
                          if (_selectedOriginCoords != null &&
                              _originController.text != (_selectedOriginCoords!['address'] ?? '')) {
                            _selectedOriginCoords = null;
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'From',
                          hintText: 'Enter starting location',
                          prefixIcon: const Icon(Icons.my_location, color: Colors.cyan),
                          suffixIcon: _originController.text.isNotEmpty
                              // Clear button takes priority — always visible when the field has text
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                                  tooltip: 'Clear starting location',
                                  onPressed: () {
                                    _originController.clear();
                                    _selectedOriginCoords = null;
                                  },
                                )
                              : _isLocatingOrigin
                                  // Spinner when field is empty and GPS is resolving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    )
                                  // GPS icon when field is empty and not locating
                                  : IconButton(
                                      icon: const Icon(Icons.gps_fixed, size: 20, color: Colors.cyan),
                                      tooltip: 'Use my current location',
                                      onPressed: _handleUseCurrentLocation,
                                    ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),

                      // Quick "Use current location" button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _isLocatingOrigin ? null : _handleUseCurrentLocation,
                          icon: _isLocatingOrigin
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.gps_fixed, size: 15, color: Colors.cyan),
                          label: const Text(
                            'Use my current location',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.cyan),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Destination Input
                      TextField(
                        controller: _destinationController,
                        onChanged: (text) {
                          if (_selectedDestCoords != null &&
                              text != (_selectedDestCoords!['address'] ?? '')) {
                            _selectedDestCoords = null;
                          }
                          _onSearchDestination(text);
                        },
                        decoration: InputDecoration(
                          labelText: 'To',
                          hintText: 'Enter destination',
                          prefixIcon: const Icon(Icons.location_on, color: AppColors.accent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          suffixIcon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                )
                              : (_destinationController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                                      tooltip: 'Clear destination',
                                      onPressed: () {
                                        _destinationController.clear();
                                        _selectedDestCoords = null;
                                        setState(() => _suggestions = []);
                                      },
                                    )
                                  : null),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Suggestions Dropdown (if searching)
              if (_suggestions.isNotEmpty)
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(top: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: _suggestions.map((s) {
                      return ListTile(
                        leading: const Icon(Icons.place_outlined, color: AppColors.primary),
                        title: Text(s['description'] ?? ''),
                        subtitle: Text(s['category'] ?? 'Hyderabad Location', style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          _destinationController.text = s['description'] ?? '';
                          _selectedDestCoords = {
                            'latitude': s['latitude'],
                            'longitude': s['longitude'],
                            'address': s['description'] ?? '',
                          };
                          setState(() => _suggestions = []);
                        },
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 16),

              // Travel Mode Toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.directions_car, size: 18), SizedBox(width: 6), Text('Driving')],
                      ),
                      selected: _travelMode == 'driving',
                      onSelected: (_) => setState(() => _travelMode = 'driving'),
                      selectedColor: AppColors.primary.withOpacity(0.18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.directions_walk, size: 18), SizedBox(width: 6), Text('Walking')],
                      ),
                      selected: _travelMode == 'walking',
                      onSelected: (_) => setState(() => _travelMode = 'walking'),
                      selectedColor: AppColors.primary.withOpacity(0.18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Error display
              if (routeProv.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(routeProv.errorMessage!, style: TextStyle(color: Colors.red.shade800)),
                ),

              // Action Button
              ElevatedButton.icon(
                onPressed: routeProv.isLoadingRoutes ? null : _handlePlanRoutes,
                icon: const Icon(Icons.directions),
                label: routeProv.isLoadingRoutes
                    ? const Text('Finding Safer Routes...')
                    : const Text('FIND SAFER ROUTES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Presets
              const Text(
                'Popular Routes in Hyderabad',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              ..._quickCorridors.map((c) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.alt_route, color: AppColors.primaryLight),
                    title: Text('${c['origin']} → ${c['destination']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      _originController.text = c['origin']!;
                      _destinationController.text = c['destination']!;
                      _selectedOriginCoords = null;
                      _selectedDestCoords = null;
                      setState(() => _suggestions = []);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
