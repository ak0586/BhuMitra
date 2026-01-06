import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/user_provider.dart';
import '../../core/saved_plots_provider.dart';
import '../../core/localization.dart';
import '../../core/auth_service.dart';
import '../../core/ad_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdManager().loadBannerAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isBannerAdLoaded = false;
            _bannerAd = null;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final savedPlots = ref.watch(savedPlotsProvider);
    final plotsCount = savedPlots.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('profile'.tr(ref)), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                              style: const TextStyle(
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
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
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
                          userProfile.phone.isEmpty
                              ? 'Not set'
                              : userProfile.phone,
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
                                    colors: [
                                      Color(0xFF66BB6A),
                                      Color(0xFF2E7D32),
                                    ],
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
                                    colors: [
                                      Color(0xFF42A5F5),
                                      Color(0xFF1976D2),
                                    ],
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
                    child: Column(
                      children: [
                        /*
                        _buildActionItem(
                          Icons.logout,
                          'logout'.tr(ref),
                          'Sign out of your account',
                          () async {
                            await ref.read(authServiceProvider).signOut();
                            await ref
                                .read(userProfileProvider.notifier)
                                .resetProfile();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          isRed: false,
                        ),
                        */
                        /*
                        const Divider(height: 1),
                        */
                        _buildActionItem(
                          Icons.delete_forever,
                          'delete_account'.tr(ref),
                          'Permanently delete your account',
                          _handleDeleteAccount,
                          isRed: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Version
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final version = snapshot.data?.version ?? '...';
                      final buildNumber = snapshot.data?.buildNumber ?? '';
                      return Text(
                        'BhuMitra v$version+$buildNumber',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_isBannerAdLoaded && _bannerAd != null)
            SafeArea(
              child: SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
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

  Future<void> _handleDeleteAccount() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) return;

    // 1. Confirm Intent
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_account'.tr(ref)),
        content: Text('delete_account_confirmation'.tr(ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr(ref)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'delete'.tr(ref),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    String password = '';

    // 2. If Password Provider, Ask for Password
    if (user.providerData.any((p) => p.providerId == 'password')) {
      if (!mounted) return;
      final pwController = TextEditingController();
      final pwInput = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('enter_password'.tr(ref)),
          content: TextField(
            controller: pwController,
            obscureText: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(ref)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, pwController.text),
              child: Text('confirm'.tr(ref)),
            ),
          ],
        ),
      );
      if (pwInput == null || pwInput.isEmpty) return;
      password = pwInput;
    }

    // 3. Call Delete
    try {
      if (!mounted) return;
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await authService.deleteAccount(password);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        await ref.read(userProfileProvider.notifier).resetProfile();
        if (context.mounted) {
          context.go('/login');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('account_deleted'.tr(ref))));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading if error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
