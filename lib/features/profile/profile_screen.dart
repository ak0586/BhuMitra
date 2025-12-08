import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/user_provider.dart';
import '../../core/saved_plots_provider.dart';
import '../../core/localization.dart';
import '../../core/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final savedPlots = ref.watch(savedPlotsProvider);
    final plotsCount = savedPlots.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('profile'.tr(ref)), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        getInitials(userProfile.name),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userProfile.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/edit-profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text('edit_profile'.tr(ref)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Personal Information
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'personal_info'.tr(ref),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildInfoItem(
                    Icons.email,
                    'email'.tr(ref),
                    userProfile.email,
                  ),
                  _buildInfoItem(
                    Icons.phone,
                    'phone'.tr(ref),
                    userProfile.phone.isEmpty ? 'Not set' : userProfile.phone,
                  ),
                  _buildInfoItem(
                    Icons.location_on,
                    'location'.tr(ref),
                    userProfile.location.isEmpty
                        ? 'Not set'
                        : userProfile.location,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Statistics
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'statistics'.tr(ref),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$plotsCount',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'plots_saved'.tr(ref),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${plotsCount * 3}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'measurements'.tr(ref),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Account Actions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildActionItem(
                Icons.logout,
                'logout'.tr(ref),
                'Sign out of your account',
                () async {
                  await ref.read(authServiceProvider).signOut();
                  await ref.read(userProfileProvider.notifier).resetProfile();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                isRed: true,
              ),
            ),

            const SizedBox(height: 24),

            // App Version
            const Text(
              'BhuMitra v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String getInitials(String name) {
    if (name.trim().isEmpty) return "";

    List<String> parts = name.trim().split(RegExp(r"\s+")); // split by space(s)

    if (parts.length == 1) {
      // Only first name
      return parts[0][0].toUpperCase();
    } else {
      // First + last
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isRed = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isRed ? Colors.red[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isRed ? Colors.red : const Color(0xFF2E7D32),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isRed ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isRed ? Colors.red[300] : Colors.grey,
        ),
      ),
    );
  }
}
