import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class FloatingSOSButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingSOSButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: AppColors.emergencyRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.emergency_share, size: 24),
        label: const Text(
          'SOS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
        ),
      ),
    );
  }
}
