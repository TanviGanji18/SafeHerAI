import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import 'personal_info_screen.dart';
import 'journey_history_screen.dart';
import 'trusted_contacts_screen.dart';
import 'safety_emergency_screen.dart';
import 'settings_screen.dart';
import 'privacy_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isGuest = auth.isGuest;

    final displayName = isGuest ? 'Guest Traveler' : (user?.fullName.isNotEmpty == true ? user!.fullName : 'SafeHer Traveler');
    final displayEmail = isGuest ? 'guest@safeher.ai' : (user?.email.isNotEmpty == true ? user!.email : '');
    final emergencyPhone = user?.phone != null && user!.phone!.isNotEmpty ? user.phone! : '+919490616555';

    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase()
        : 'SH';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // User Profile Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isGuest) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Guest Mode',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            displayEmail,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 13, color: AppColors.safeGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Emergency Phone: $emergencyPhone',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.safeGreen),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Profile Section Menu Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Column(
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    subtitle: 'View and edit identity & emergency phone',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.explore_outlined,
                    title: 'My Journeys',
                    subtitle: 'Review completed routes and safety scores',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JourneyHistoryScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.group_outlined,
                    title: 'Trusted Contacts',
                    subtitle: 'Manage automatic SOS emergency recipients',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TrustedContactsScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.security_outlined,
                    title: 'Safety & Emergency',
                    subtitle: 'Official helplines and nearby police/hospitals',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SafetyEmergencyScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Navigation, route, and alert preferences',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy',
                    subtitle: 'How SafeHer AI protects and uses location data',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'About SafeHer AI',
                    subtitle: '7-factor safety methodology and disclaimers',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, size: 20, color: AppColors.emergencyRed),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emergencyRed,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFECACA)),
                backgroundColor: const Color(0xFFFEF2F2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withOpacity(0.08),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
