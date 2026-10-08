import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ComponentBar extends StatelessWidget {
  final String title;
  final double awardedPts;
  final double maxPts;
  final double normalizedValue;
  final String description;
  final IconData icon;

  const ComponentBar({
    Key? key,
    required this.title,
    required this.awardedPts,
    required this.maxPts,
    required this.normalizedValue,
    required this.description,
    required this.icon,
  }) : super(key: key);

  Color _getColor() {
    final ratio = awardedPts / maxPts;
    if (ratio >= 0.75) return AppColors.safeGreen;
    if (ratio >= 0.50) return AppColors.warningAmber;
    return AppColors.cautionRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final fraction = (awardedPts / maxPts).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              Text(
                '${awardedPts.toStringAsFixed(1)} / ${maxPts.toStringAsFixed(1)} pts',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
          ),
        ],
      ),
    );
  }
}
