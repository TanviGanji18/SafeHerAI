import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/journey_provider.dart';

class JourneyReportScreen extends StatefulWidget {
  const JourneyReportScreen({Key? key}) : super(key: key);

  @override
  State<JourneyReportScreen> createState() => _JourneyReportScreenState();
}

class _JourneyReportScreenState extends State<JourneyReportScreen> {
  String _selectedExperience = 'Comfortable';
  final Set<String> _selectedIssues = {};
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _experienceOptions = [
    {
      'label': 'Comfortable',
      'icon': Icons.sentiment_very_satisfied,
      'color': AppColors.safeGreen,
    },
    {
      'label': 'Average',
      'icon': Icons.sentiment_neutral,
      'color': Colors.amber.shade700,
    },
    {
      'label': 'Felt Unsafe',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': AppColors.emergencyRed,
    },
  ];

  final List<String> _availableIssues = [
    'Unsafe area',
    'Poor road condition',
    'Heavy traffic',
    'Poor lighting',
    'Suspicious activity',
    'Accident / emergency',
    'Other',
    'No issue',
  ];

  void _toggleIssue(String issue) {
    setState(() {
      if (issue == 'No issue') {
        _selectedIssues.clear();
        _selectedIssues.add('No issue');
      } else {
        _selectedIssues.remove('No issue');
        if (_selectedIssues.contains(issue)) {
          _selectedIssues.remove(issue);
        } else {
          _selectedIssues.add(issue);
        }
      }
    });
  }

  void _handleSubmitReport() async {
    setState(() => _isSubmitting = true);
    final journeyProv = Provider.of<JourneyProvider>(context, listen: false);

    await journeyProv.submitJourneyReport(
      routeExperience: _selectedExperience,
      issuesNoticed: _selectedIssues.toList(),
      comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.safeGreen,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Thank you! Your feedback helps make Hyderabad routes safer for women.'),
              ),
            ],
          ),
        ),
      );
      Navigator.of(context).pop(); // Back to Home
    }
  }

  void _handleSkip() {
    final journeyProv = Provider.of<JourneyProvider>(context, listen: false);
    journeyProv.skipFeedback();
    Navigator.of(context).pop(); // Back to Home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Journey Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: const Text('SKIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Title
              const Text(
                'How was your journey?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your real observations help validate spatial data and improve future safety predictions.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),

              // 1. ROUTE EXPERIENCE
              const Text(
                'ROUTE EXPERIENCE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                children: _experienceOptions.map((opt) {
                  final isSelected = _selectedExperience == opt['label'];
                  final color = opt['color'] as Color;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedExperience = opt['label'] as String),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.12) : Colors.white,
                          border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Icon(opt['icon'] as IconData, color: isSelected ? color : Colors.grey.shade500, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              opt['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? color : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 2. ISSUES NOTICED
              const Text(
                'ISSUES NOTICED (OPTIONAL)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableIssues.map((issue) {
                  final isSelected = _selectedIssues.contains(issue);
                  return FilterChip(
                    label: Text(issue),
                    selected: isSelected,
                    onSelected: (_) => _toggleIssue(issue),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 3. TELL US MORE
              const Text(
                'TELL US MORE (OPTIONAL)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Good streetlights along Main Road, felt safe near metro...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 28),

              // SUBMIT REPORT BUTTON
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
