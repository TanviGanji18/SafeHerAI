import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SafetyBadge extends StatelessWidget {
  final double score;
  final String tier;
  final bool isCompact;

  const SafetyBadge({
    Key? key,
    required this.score,
    required this.tier,
    this.isCompact = false,
  }) : super(key: key);

  Color _getColor() {
    if (score >= 75.0) return AppColors.safeGreen;
    if (score >= 50.0) return AppColors.warningAmber;
    return AppColors.cautionRed;
  }

  IconData _getIcon() {
    if (score >= 75.0) return Icons.verified_user_rounded;
    if (score >= 50.0) return Icons.shield_outlined;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(), size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              '${score.toStringAsFixed(1)} / 100',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: Icon(_getIcon(), size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Safety Score: ${score.toStringAsFixed(1)} / 100',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                tier,
                style: TextStyle(color: color.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
