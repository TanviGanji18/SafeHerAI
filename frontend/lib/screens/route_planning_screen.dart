import 'package:flutter/material.dart';
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
  final _originController = TextEditingController(text: 'Secunderabad Railway Station');
  final _destinationController = TextEditingController(text: 'Charminar, Old City');
  String _travelMode = 'driving';
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;

  final List<Map<String, String>> _quickCorridors = [
    {'origin': 'Secunderabad Railway Station', 'destination': 'Charminar, Old City'},
    {'origin': 'Gachibowli Junction', 'destination': 'Begumpet Airport / Station'},
    {'origin': 'Hitec City / Cyber Towers, Madhapur', 'destination': 'Banjara Hills Road No. 1'},
    {'origin': 'Kukatpally Y-Junction', 'destination': 'Lakdikapul Metro Station'},
  ];

  void _onSearchDestination(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
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
    final routeProv = Provider.of<RouteProvider>(context, listen: false);
    final success = await routeProv.planRoutes(
      origin: {'address': _originController.text.trim()},
      destination: {'address': _destinationController.text.trim()},
      travelMode: _travelMode,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RouteComparisonScreen()),
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
                        decoration: InputDecoration(
                          labelText: 'From',
                          prefixIcon: const Icon(Icons.my_location, color: Colors.cyan),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Destination Input
                      TextField(
                        controller: _destinationController,
                        onChanged: _onSearchDestination,
                        decoration: InputDecoration(
                          labelText: 'To',
                          prefixIcon: const Icon(Icons.location_on, color: AppColors.accent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          suffixIcon: _isSearching
                              ? const SizedBox(width: 20, height: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                              : null,
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
                      _handlePlanRoutes();
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
