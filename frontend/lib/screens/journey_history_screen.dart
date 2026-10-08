import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/journey_provider.dart';
import '../models/journey_model.dart';
import 'journey_details_screen.dart';

class JourneyHistoryScreen extends StatefulWidget {
  const JourneyHistoryScreen({Key? key}) : super(key: key);

  @override
  State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
}

class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final journeyProv = Provider.of<JourneyProvider>(context, listen: false);
    final userId = auth.user?.id ?? 'anonymous_user';
    journeyProv.fetchJourneyHistory(userId);
  }

  @override
  Widget build(BuildContext context) {
    final journeyProv = Provider.of<JourneyProvider>(context);
    final history = journeyProv.journeyHistory;
    final isLoading = journeyProv.isLoadingHistory;

    final dateFormat = DateFormat('d MMM yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Journeys'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text('Loading your journeys...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              )
            : history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.navigation_outlined, size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No journeys yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your completed journeys will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.explore),
                            label: const Text('Find a Route'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return _buildJourneyCard(context, item, dateFormat, timeFormat);
                    },
                  ),
      ),
    );
  }

  Widget _buildJourneyCard(
    BuildContext context,
    ActiveJourney item,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    final formattedDate = '${dateFormat.format(item.startTime)} · ${timeFormat.format(item.startTime)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JourneyDetailsScreen(journey: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route Title & Compass Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧭 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      '${item.originAddress} → ${item.destinationAddress}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Duration & Distance
              Text(
                '${item.durationMin.toStringAsFixed(0)} min · ${item.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const Divider(height: 20),

              // Safety Score & Feedback Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safety Score',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            item.safetyScore.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: item.safetyScore >= 75 ? AppColors.safeGreen : AppColors.warningAmber,
                            ),
                          ),
                          const Text(
                            ' / 100',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (item.feedback != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.safeGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, size: 14, color: AppColors.safeGreen),
                          const SizedBox(width: 4),
                          Text(
                            item.feedback!.routeExperience,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.safeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Date/Time & View Journey Link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Row(
                    children: [
                      Text(
                        'View Journey',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                    ],
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
