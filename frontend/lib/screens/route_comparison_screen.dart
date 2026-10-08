import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/route_provider.dart';
import '../providers/journey_provider.dart';
import '../models/route_model.dart';
import '../widgets/route_card.dart';
import 'safety_breakdown_screen.dart';
import 'active_journey_screen.dart';

class RouteComparisonScreen extends StatelessWidget {
  const RouteComparisonScreen({Key? key}) : super(key: key);

  void _startJourney(BuildContext context, EnrichedRoute route) async {
    final routeProv = Provider.of<RouteProvider>(context, listen: false);
    final journeyProv = Provider.of<JourneyProvider>(context, listen: false);

    final orig = routeProv.planResult?.origin != null
        ? {'address': routeProv.planResult!.originName ?? 'Origin', 'lat': routeProv.planResult!.origin.latitude, 'lon': routeProv.planResult!.origin.longitude}
        : {'address': 'Origin'};

    final dest = routeProv.planResult?.destination != null
        ? {'address': routeProv.planResult!.destinationName ?? 'Destination', 'lat': routeProv.planResult!.destination.latitude, 'lon': routeProv.planResult!.destination.longitude}
        : {'address': 'Destination'};

    await journeyProv.startJourney(
      route: route,
      origin: orig,
      destination: dest,
    );

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ActiveJourneyScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProv = Provider.of<RouteProvider>(context);
    final plan = routeProv.planResult;

    if (plan == null || plan.routes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Route Alternatives')),
        body: const Center(child: Text('No routes evaluated yet. Plan a route first.')),
      );
    }

    final selected = routeProv.selectedRoute ?? plan.routes.first;
    final saferRoute = plan.routes.firstWhere((r) => r.isRecommendedSafer, orElse: () => plan.routes.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Route Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  // 1. Clean Trip Header: From -> To
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('FROM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.safeGreen, letterSpacing: 0.6)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                plan.originName ?? 'Origin Point',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 14),
                          child: SizedBox(height: 10, child: VerticalDivider(thickness: 1.5, color: Colors.grey)),
                        ),
                        Row(
                          children: [
                            const Text('TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emergencyRed, letterSpacing: 0.6)),
                            const SizedBox(width: 22),
                            Expanded(
                              child: Text(
                                plan.destinationName ?? 'Destination',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. "Why this route?" Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.safeGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.safeGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield, color: AppColors.safeGreen, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Why this route?',
                              style: TextStyle(color: AppColors.safeGreen, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Provides a stronger overall safety profile compared with available alternatives.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        _buildWhyBullet('Police stations nearby along the corridor'),
                        _buildWhyBullet('Emergency healthcare facilities accessible along the way'),
                        _buildWhyBullet('Public transport network available along the route'),
                        _buildWhyBullet('Avoids identified accident-prone hazard locations'),
                        _buildWhyBullet('Considers official crime levels of zones crossed'),
                        _buildWhyBullet('Keeps the route reasonably direct'),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SafetyBreakdownScreen(route: saferRoute)),
                            );
                          },
                          child: const Text(
                            'View safety details →',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Text(
                      'Route Alternatives',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),

                  // 3. Route Cards List
                  ...plan.routes.map((route) {
                    final isSelected = route.routeId == selected.routeId;
                    return RouteCard(
                      route: route,
                      isSelected: isSelected,
                      onSelect: () => routeProv.selectRoute(route),
                      onViewDetails: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SafetyBreakdownScreen(route: route)),
                        );
                      },
                      onStartJourney: () => _startJourney(context, route),
                    );
                  }).toList(),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // 4. Fixed Bottom START JOURNEY Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _startJourney(context, selected),
                icon: const Icon(Icons.navigation, size: 20),
                label: Text(
                  'START JOURNEY (${selected.isRecommendedSafer ? "SAFER ROUTE" : selected.isFastest ? "FASTEST ROUTE" : "ALTERNATIVE"})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected.isRecommendedSafer ? AppColors.safeGreen : AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✓ ', style: TextStyle(color: AppColors.safeGreen, fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
