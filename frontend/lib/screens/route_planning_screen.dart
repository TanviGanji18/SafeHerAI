import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
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
  final FocusNode _originFocusNode = FocusNode();
  final FocusNode _destFocusNode = FocusNode();
  bool _isOriginActive = false;

  String _travelMode = 'driving';
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _isLocatingOrigin = false;
  bool _isSearchingOrigin = false;
  List<Map<String, dynamic>> _originSuggestions = [];

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

    _originFocusNode.addListener(() {
      if (_originFocusNode.hasFocus && mounted) {
        setState(() => _isOriginActive = true);
      }
    });
    _destFocusNode.addListener(() {
      if (_destFocusNode.hasFocus && mounted) {
        setState(() => _isOriginActive = false);
      }
    });

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
    _originFocusNode.dispose();
    _destFocusNode.dispose();
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

      if (!mounted) return;
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

  /// Opens a full-screen map picker so the user can tap a location.
  /// [forOrigin] = true → sets origin, false → sets destination.
  Future<void> _openMapPicker({required bool forOrigin}) async {
    final routeProv = Provider.of<RouteProvider>(context, listen: false);
    // Default center: user location or Hyderabad center
    double lat = AppConstants.hyderabadCenterLat;
    double lng = AppConstants.hyderabadCenterLon;
    if (_selectedOriginCoords != null && forOrigin == false) {
      lat = (_selectedOriginCoords!['latitude'] as num?)?.toDouble() ?? lat;
      lng = (_selectedOriginCoords!['longitude'] as num?)?.toDouble() ?? lng;
    } else if (forOrigin && _lastResolvedPosition != null) {
      lat = _lastResolvedPosition!.latitude;
      lng = _lastResolvedPosition!.longitude;
    }

    final picked = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _MapPickerScreen(
          initialLat: lat,
          initialLng: lng,
          title: forOrigin ? 'Select Starting Location' : 'Select Destination',
          forOrigin: forOrigin,
          apiService: routeProv.apiService,
        ),
      ),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        if (forOrigin) {
          _originController.text = picked['address'] ?? 'Selected location';
          _selectedOriginCoords = picked;
          _userManuallyEditedOrigin = true;
          _originSuggestions = [];
          _isOriginActive = false;
        } else {
          _destinationController.text = picked['address'] ?? 'Selected location';
          _selectedDestCoords = picked;
          _suggestions = [];
        }
      });
    }
  }

  void _onSearchOrigin(String query) async {
    if (query.trim().length < 2) {
      if (_originSuggestions.isNotEmpty) {
        setState(() => _originSuggestions = []);
      }
      return;
    }
    setState(() => _isSearchingOrigin = true);
    final routeProv = Provider.of<RouteProvider>(context, listen: false);
    final results = await routeProv.apiService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _originSuggestions = results;
        _isSearchingOrigin = false;
      });
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
              // Search Inputs Card (Rapido-Style Pickup & Destination Experience)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Origin Input (From)
                      TextField(
                        controller: _originController,
                        focusNode: _originFocusNode,
                        onTap: () => setState(() => _isOriginActive = true),
                        onChanged: (text) {
                          if (_selectedOriginCoords != null &&
                              _originController.text != (_selectedOriginCoords!['address'] ?? '')) {
                            _selectedOriginCoords = null;
                          }
                          _userManuallyEditedOrigin = true;
                          _onSearchOrigin(text);
                        },
                        decoration: InputDecoration(
                          labelText: 'From',
                          hintText: 'Enter starting location',
                          prefixIcon: const Icon(Icons.my_location, color: Colors.cyan),
                          suffixIcon: _originController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                                  tooltip: 'Clear starting location',
                                  onPressed: () {
                                    _originController.clear();
                                    _selectedOriginCoords = null;
                                    _userManuallyEditedOrigin = false;
                                    setState(() => _originSuggestions = []);
                                  },
                                )
                              : _isLocatingOrigin
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

                      // Origin Suggestions Dropdown
                      if (_originSuggestions.isNotEmpty)
                        Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: AppColors.surface,
                          child: Column(
                            children: _originSuggestions.map((s) {
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.place_outlined, color: Colors.cyan, size: 20),
                                title: Text(s['description'] ?? '', style: const TextStyle(fontSize: 13)),
                                subtitle: Text(s['category'] ?? 'Hyderabad Location', style: const TextStyle(fontSize: 11)),
                                onTap: () {
                                  _originController.text = s['description'] ?? '';
                                  _selectedOriginCoords = {
                                    'latitude': s['latitude'],
                                    'longitude': s['longitude'],
                                    'address': s['description'] ?? '',
                                  };
                                  _userManuallyEditedOrigin = true;
                                  setState(() {
                                    _originSuggestions = [];
                                    _isOriginActive = false;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 6),

                      // Destination Input (To)
                      TextField(
                        controller: _destinationController,
                        focusNode: _destFocusNode,
                        onTap: () => setState(() => _isOriginActive = false),
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

                      // Destination Suggestions Dropdown
                      if (_suggestions.isNotEmpty)
                        Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(top: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: AppColors.surface,
                          child: Column(
                            children: _suggestions.map((s) {
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.location_pin, color: AppColors.accent, size: 20),
                                title: Text(s['description'] ?? '', style: const TextStyle(fontSize: 13)),
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

                      const SizedBox(height: 12),

                      // Single Shared Rapido-Style "Select on map" Action
                      InkWell(
                        onTap: () => _openMapPicker(forOrigin: _isOriginActive),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: (_isOriginActive ? Colors.teal : AppColors.accent).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (_isOriginActive ? Colors.teal : AppColors.accent).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pin_drop_rounded,
                                size: 22,
                                color: _isOriginActive ? Colors.teal : AppColors.accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Select on map',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: (_isOriginActive ? Colors.teal : AppColors.accent).withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _isOriginActive ? 'For Starting Location (From)' : 'For Destination (To)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _isOriginActive ? Colors.teal : AppColors.accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isOriginActive
                                          ? 'Pinpoint starting location on live street map'
                                          : 'Pinpoint destination on live street map',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                            ],
                          ),
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
                    title: Text('${c['origin']} \u2192 ${c['destination']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

/// Full-screen real street map picker allowing the user to pan/zoom and select a location.
/// Reuses flutter_map and OpenStreetMap / CartoDB tiles with live reverse geocoding.
class _MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String title;
  final bool forOrigin;
  final dynamic apiService;

  const _MapPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.title,
    required this.forOrigin,
    required this.apiService,
  });

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  final fmap.MapController _mapController = fmap.MapController();
  late double _pickedLat;
  late double _pickedLng;
  String _pickedAddress = 'Locating street address...';
  bool _isResolving = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _pickedLat = widget.initialLat;
    _pickedLng = widget.initialLng;
    _resolveAddress(_pickedLat, _pickedLng);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(fmap.MapCamera camera, bool hasGesture) {
    _pickedLat = camera.center.latitude;
    _pickedLng = camera.center.longitude;
    if (hasGesture) {
      _debounceTimer?.cancel();
      if (!_isResolving) {
        setState(() => _isResolving = true);
      }
      _debounceTimer = Timer(const Duration(milliseconds: 350), () {
        _resolveAddress(_pickedLat, _pickedLng);
      });
    }
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    setState(() => _isResolving = true);
    try {
      final address = await widget.apiService.reverseGeocode(lat, lng);
      if (mounted) {
        setState(() {
          _pickedAddress = address;
          _isResolving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pickedAddress = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
          _isResolving = false;
        });
      }
    }
  }

  Future<void> _jumpToGps() async {
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos != null && mounted) {
        _mapController.move(ll.LatLng(pos.latitude, pos.longitude), 16.0);
        _pickedLat = pos.latitude;
        _pickedLng = pos.longitude;
        _resolveAddress(_pickedLat, _pickedLng);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.forOrigin ? Colors.teal : AppColors.accent;
    final modeLabel = widget.forOrigin ? 'PICKUP LOCATION' : 'DESTINATION';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Live Street Map — OpenStreetMap standard light tiles (same as main map)
          fmap.FlutterMap(
            mapController: _mapController,
            options: fmap.MapOptions(
              initialCenter: ll.LatLng(_pickedLat, _pickedLng),
              initialZoom: 15.5,
              minZoom: 6.0,
              maxZoom: 19.0,
              interactionOptions: const fmap.InteractionOptions(
                flags: fmap.InteractiveFlag.all,
              ),
              onPositionChanged: _onPositionChanged,
              onTap: (tapPos, point) {
                _mapController.move(point, _mapController.camera.zoom);
                _pickedLat = point.latitude;
                _pickedLng = point.longitude;
                _resolveAddress(_pickedLat, _pickedLng);
              },
            ),
            children: [
              fmap.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.safeher_ai',
              ),
              const fmap.RichAttributionWidget(
                attributions: [
                  fmap.TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // 2. Center Pin (Rapido/Uber style fixed pin pointing to exact map center)
          Center(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      modeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.location_pin,
                    color: accentColor,
                    size: 44,
                  ),
                ],
              ),
            ),
          ),

          // Center target dot
          Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Zoom and GPS Controls
          Positioned(
            right: 14,
            bottom: 180,
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.add,
                  onPressed: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, (z + 1).clamp(6.0, 19.0));
                  },
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, (z - 1).clamp(6.0, 19.0));
                  },
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.my_location,
                  iconColor: accentColor,
                  onPressed: _jumpToGps,
                ),
              ],
            ),
          ),

          // 4. Bottom Confirmation Card
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.15),
                          ),
                          child: Icon(Icons.location_on, color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    modeLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                  if (_isResolving) ...[
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isResolving ? 'Resolving street address...' : _pickedAddress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_pickedLat.toStringAsFixed(5)}°N, ${_pickedLng.toStringAsFixed(5)}°E',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'latitude': _pickedLat,
                          'longitude': _pickedLng,
                          'address': _pickedAddress,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.forOrigin ? AppColors.primary : AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Confirm ${widget.forOrigin ? "Starting" : "Destination"} Location',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}