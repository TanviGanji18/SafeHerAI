import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/journey_model.dart';
import '../widgets/safety_badge.dart';
import '../widgets/component_bar.dart';

class JourneyDetailsScreen extends StatelessWidget {
  final ActiveJourney journey;

  const JourneyDetailsScreen({Key? key, required this.journey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    final timeFormat = DateFormat('h:mm a');
    final startFormatted = '${dateFormat.format(journey.startTime)} • ${timeFormat.format(journey.startTime)}';
    final endFormatted = journey.endTime != null ? timeFormat.format(journey.endTime!) : 'Completed';

    final route = journey.selectedRoute;
    final score = journey.safetyScore;

    // 7-Factor safety breakdown: reuse existing genuine route contributions
    final double policePts = route.contributions.policePts;
    final double medicalPts = route.contributions.medicalPts;
    final double transitPts = route.contributions.transitPts;
    final double arterialPts = route.contributions.arterialPts;
    final double crimePts = route.contributions.crimeCompliancePts;
    final double blackspotPts = route.contributions.blackspotCompliancePts;
    final double efficiencyPts = route.contributions.exposureCompliancePts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Journey Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Overview Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.explore, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${journey.originAddress} → ${journey.destinationAddress}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startFormatted,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric(
                          icon: Icons.timer_outlined,
                          title: 'Duration',
                          value: '${journey.durationMin.toStringAsFixed(0)} min',
                        ),
                        _buildMetric(
                          icon: Icons.straighten,
                          title: 'Distance',
                          value: '${journey.distanceKm.toStringAsFixed(1)} km',
                        ),
                        _buildMetric(
                          icon: Icons.shield_outlined,
                          title: 'Safety Score',
                          value: '${journey.safetyScore.toStringAsFixed(1)}/100',
                          valueColor: journey.safetyScore >= 75 ? AppColors.safeGreen : AppColors.warningAmber,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: SafetyBadge(
                        score: journey.safetyScore,
                        tier: journey.safetyTier,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Route & Emergency Status Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Route & Navigation Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Selected Corridor', journey.routeSummary),
                    _buildDetailRow('Departed', timeFormat.format(journey.startTime)),
                    _buildDetailRow('Concluded', endFormatted),
                    _buildDetailRow('Status', journey.journeyStatus.toUpperCase()),
                    _buildDetailRow(
                      'Emergency/SOS Status',
                      journey.emergencyOccurred ? 'SOS Alert Triggered' : 'Normal (No Incidents)',
                      textColor: journey.emergencyOccurred ? AppColors.emergencyRed : AppColors.safeGreen,
                    ),
                    if (journey.sosEvents.isNotEmpty)
                      _buildDetailRow(
                        'SOS Event Log',
                        '${journey.sosEvents.length} alert event(s) recorded at live coordinates',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Feedback Card (if feedback submitted)
            if (journey.feedback != null) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Traveler Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Route Experience: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.safeGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              journey.feedback!.routeExperience,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.safeGreen),
                            ),
                          ),
                        ],
                      ),
                      if (journey.feedback!.issuesNoticed.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Issues Noticed: ${journey.feedback!.issuesNoticed.join(', ')}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      if (journey.feedback!.comments != null && journey.feedback!.comments!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Comments: "${journey.feedback!.comments}"',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 7-Factor Safety Breakdown Section
            const Text(
              'Seven-Factor Safety Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Evaluated across genuine Hyderabad spatial infrastructure and crime statistics:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // Factor 1: Police Accessibility
            ComponentBar(
              title: '1. Police Accessibility',
              awardedPts: policePts,
              maxPts: 25.0,
              normalizedValue: policePts / 25.0,
              description: 'Avg distance: ${route.rawFeatures.avgPoliceDistKm.toStringAsFixed(2)} km • ${route.rawFeatures.policeWithin1kmCount} stations nearby',
              icon: Icons.local_police_outlined,
            ),

            // Factor 2: Emergency Healthcare
            ComponentBar(
              title: '2. Emergency Healthcare',
              awardedPts: medicalPts,
              maxPts: 15.0,
              normalizedValue: medicalPts / 15.0,
              description: 'Min hospital distance: ${route.rawFeatures.minHospitalDistKm.toStringAsFixed(2)} km',
              icon: Icons.local_hospital_outlined,
            ),

            // Factor 3: Public Transport
            ComponentBar(
              title: '3. Public Transport Density',
              awardedPts: transitPts,
              maxPts: 15.0,
              normalizedValue: transitPts / 15.0,
              description: '${route.rawFeatures.transitCountWithin500m} metro & bus transit hubs within 500m',
              icon: Icons.directions_subway_outlined,
            ),

            // Factor 4: Road Hierarchy
            ComponentBar(
              title: '4. Road Type / Arterial Road Hierarchy',
              awardedPts: arterialPts,
              maxPts: 15.0,
              normalizedValue: arterialPts / 15.0,
              description: '${route.rawFeatures.arterialLengthKm.toStringAsFixed(2)} km on classified arterial corridors',
              icon: Icons.alt_route_outlined,
            ),

            // Factor 5: Crime Exposure
            ComponentBar(
              title: '5. Crime Exposure Compliance',
              awardedPts: crimePts,
              maxPts: 15.0,
              normalizedValue: crimePts / 15.0,
              description: route.rawFeatures.traversedZones.isNotEmpty
                  ? 'Police zones: ${route.rawFeatures.traversedZones.join(", ")}'
                  : 'Evaluation based on Hyderabad Police crime statistical reviews',
              icon: Icons.gavel_outlined,
            ),

            // Factor 6: Accident Black Spots
            ComponentBar(
              title: '6. Accident-Prone Areas / Black Spots',
              awardedPts: blackspotPts,
              maxPts: 10.0,
              normalizedValue: blackspotPts / 10.0,
              description: route.rawFeatures.blackspotCount == 0
                  ? 'Zero identified traffic accident black spots intersecting corridor'
                  : 'Passes near ${route.rawFeatures.blackspotCount} identified high-accident junctions',
              icon: Icons.car_crash_outlined,
            ),

            // Factor 7: Route Efficiency
            ComponentBar(
              title: '7. Route Efficiency',
              awardedPts: efficiencyPts,
              maxPts: 5.0,
              normalizedValue: efficiencyPts / 5.0,
              description: 'Penalizes indirect or winding detours that unnecessarily extend nighttime exposure',
              icon: Icons.navigation_outlined,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
