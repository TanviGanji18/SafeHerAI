import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/route_model.dart';
import '../widgets/safety_badge.dart';
import '../widgets/component_bar.dart';

class SafetyBreakdownScreen extends StatelessWidget {
  final EnrichedRoute route;

  const SafetyBreakdownScreen({Key? key, required this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final comp = route.components;
    final pts = route.contributions;
    final raw = route.rawFeatures;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Factor Breakdown'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Score Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    route.summary,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SafetyBadge(score: route.safetyScore, tier: route.safetyTier),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${route.durationMin.toStringAsFixed(0)} mins', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text(' • '),
                      Text('${route.distanceKm.toStringAsFixed(2)} km distance'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Factor Title
            const Text(
              'Multi-Criteria Component Point Contributions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Points awarded out of 100 maximum total score based on verified data:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            // 1. Police Proximity
            ComponentBar(
              title: '1. Police Station Accessibility',
              awardedPts: pts.policePts,
              maxPts: 25.0,
              normalizedValue: comp.sPolice,
              description: 'Avg distance along route: ${raw.avgPoliceDistKm.toStringAsFixed(2)} km • ${raw.policeWithin1kmCount} stations within 1 km corridor.',
              icon: Icons.local_police_outlined,
            ),

            // 2. Emergency Healthcare
            ComponentBar(
              title: '2. Emergency Medical Proximity',
              awardedPts: pts.medicalPts,
              maxPts: 15.0,
              normalizedValue: comp.sMedical,
              description: 'Distance to closest emergency hospital: ${raw.minHospitalDistKm.toStringAsFixed(2)} km.',
              icon: Icons.local_hospital_outlined,
            ),

            // 3. Public Transit Presence
            ComponentBar(
              title: '3. Public Transit Density',
              awardedPts: pts.transitPts,
              maxPts: 15.0,
              normalizedValue: comp.sTransit,
              description: 'Contextual Proxy: ${raw.transitCountWithin500m} metro & bus stations within 500m corridor.',
              icon: Icons.directions_subway_outlined,
            ),

            // 4. Arterial Road Alignment
            ComponentBar(
              title: '4. Arterial Road Hierarchy',
              awardedPts: pts.arterialPts,
              maxPts: 15.0,
              normalizedValue: comp.sArterial,
              description: 'Contextual Proxy: ${raw.arterialLengthKm.toStringAsFixed(2)} km along classified primary/trunk corridors.',
              icon: Icons.alt_route_outlined,
            ),

            // 5. Jurisdictional Crime Volume
            ComponentBar(
              title: '5. Jurisdictional Crime Volume Compliance',
              awardedPts: pts.crimeCompliancePts,
              maxPts: 15.0,
              normalizedValue: 1.0 - comp.pCrime,
              description: 'Traversed police zones: ${raw.traversedZones.join(", ")}. Evaluated from official Hyderabad City Police annual reviews.',
              icon: Icons.gavel_outlined,
            ),

            // 6. Accident Black Spot Hazard
            ComponentBar(
              title: '6. Accident Black Spot Avoidance',
              awardedPts: pts.blackspotCompliancePts,
              maxPts: 10.0,
              normalizedValue: 1.0 - comp.pBlackspot,
              description: raw.blackspotCount == 0
                  ? 'Zero identified traffic accident black spots intersecting corridor (+10.0 pts).'
                  : 'Passes near ${raw.blackspotCount} known collision junctions. Caution advised.',
              icon: Icons.car_crash_outlined,
            ),

            // 7. Route Directness & Exposure
            ComponentBar(
              title: '7. Direct Route Efficiency',
              awardedPts: pts.exposureCompliancePts,
              maxPts: 5.0,
              normalizedValue: 1.0 - comp.pExposure,
              description: 'Penalizes indirect or winding detours that unnecessarily extend nighttime travel time.',
              icon: Icons.navigation_outlined,
            ),

            const SizedBox(height: 20),

            // Academic Integrity & Limitations Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.brown, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Data Limitations & Contextual Caveats',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Indian law and police practices prohibit publishing micro-level GPS coordinates of crimes against women. Official crime volume is aggregated by police zone.\n'
                    '• Public transit and major roads are contextual infrastructure proxies and do not guarantee individual safety on any given night.\n'
                    '• The Safety Score is an analytical comparative estimate designed to rank navigation alternatives and does not guarantee absolute safety.',
                    style: TextStyle(fontSize: 11, color: Colors.brown, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
