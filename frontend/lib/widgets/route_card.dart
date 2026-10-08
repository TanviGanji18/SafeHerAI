import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/route_model.dart';
import 'safety_badge.dart';

class RouteCard extends StatelessWidget {
  final EnrichedRoute route;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onViewDetails;
  final VoidCallback? onStartJourney;

  const RouteCard({
    Key? key,
    required this.route,
    required this.isSelected,
    required this.onSelect,
    required this.onViewDetails,
    this.onStartJourney,
  }) : super(key: key);

  String get _categoryTitle {
    if (route.isRecommendedSafer) {
      return '🛡️ SAFER ROUTE';
    } else if (route.isFastest) {
      return '⚡ FASTEST ROUTE';
    } else {
      return 'ALTERNATIVE ROUTE';
    }
  }

  Color get _categoryColor {
    if (route.isRecommendedSafer) {
      return AppColors.safeGreen;
    } else if (route.isFastest) {
      return Colors.blue.shade700;
    } else {
      return Colors.blueGrey.shade700;
    }
  }

  List<Map<String, dynamic>> get _bulletPoints {
    final raw = route.rawFeatures;
    final pts = route.contributions;
    final list = <Map<String, dynamic>>[];

    if (route.isRecommendedSafer) {
      if (raw.policeWithin1kmCount > 0 || pts.policePts >= 18) {
        list.add({'text': 'More police coverage (${raw.policeWithin1kmCount} within 1 km)', 'isPro': true});
      } else {
        list.add({'text': 'Monitored corridor with police proximity', 'isPro': true});
      }
      if (raw.minHospitalDistKm <= 2.0 || pts.medicalPts >= 12) {
        list.add({'text': 'Better emergency medical access', 'isPro': true});
      }
      if (raw.blackspotCount == 0) {
        list.add({'text': 'Fewer identified accident-prone areas (Zero black spots)', 'isPro': true});
      } else {
        list.add({'text': 'Avoids major high-collision black spots', 'isPro': true});
      }
    } else if (route.isFastest) {
      list.add({'text': 'Saves travel time (${route.durationMin.toStringAsFixed(0)} mins total)', 'isPro': true});
      list.add({'text': 'Slightly lower safety coverage (${route.safetyScore.toStringAsFixed(1)} / 100)', 'isPro': false});
      if (raw.blackspotCount > 0) {
        list.add({'text': 'Crosses near accident black spot area', 'isPro': false});
      }
    } else {
      list.add({'text': 'Different road corridor (${route.distanceKm.toStringAsFixed(1)} km)', 'isPro': true});
      list.add({'text': 'Different safety conditions (${route.safetyScore.toStringAsFixed(1)} / 100)', 'isPro': false});
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? _categoryColor : AppColors.border;

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: isSelected ? 2.0 : 1.0),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Category Header & Safety Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _categoryTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: _categoryColor,
                    ),
                  ),
                  SafetyBadge(score: route.safetyScore, tier: route.safetyTier, isCompact: true),
                ],
              ),
              const SizedBox(height: 8),

              // 2. Metrics: Time · Distance
              Row(
                children: [
                  Text(
                    '${route.durationMin.toStringAsFixed(0)} min',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const Text(' · ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                  Text(
                    '${route.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Natural Bullet Points (Real Backend Data)
              ..._bulletPoints.map((b) {
                final isPro = b['isPro'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? '✓ ' : '⚠ ',
                        style: TextStyle(
                          color: isPro ? AppColors.safeGreen : Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          b['text'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isPro ? Colors.black87 : Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 12),

              // 4. Action Row (View Details + Start Journey)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline, size: 15),
                    label: const Text('View safety details →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 28),
                    ),
                  ),
                  if (onStartJourney != null)
                    ElevatedButton.icon(
                      onPressed: onStartJourney,
                      icon: const Icon(Icons.navigation, size: 14),
                      label: const Text('START JOURNEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: route.isRecommendedSafer ? AppColors.safeGreen : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
