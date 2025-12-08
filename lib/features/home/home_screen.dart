import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/location_helper.dart';
import '../../core/saved_plots_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/localization.dart';
import '../../core/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _currentAddress = 'Detecting Location...';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final status = await LocationHelper.requestLocationPermission();

    if (!mounted) return;

    if (status == LocationPermissionStatus.granted) {
      await _loadCurrentLocation();
    } else if (status == LocationPermissionStatus.serviceDisabled) {
      _showServiceDisabledDialog();
    } else if (status == LocationPermissionStatus.denied) {
      _showPermissionDeniedDialog();
    } else if (status == LocationPermissionStatus.deniedForever) {
      _showPermissionPermanentlyDeniedDialog();
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await LocationHelper.requestLocationPermission();

    if (!mounted) return;

    if (status == LocationPermissionStatus.serviceDisabled) {
      _showServiceDisabledDialog();
    } else if (status == LocationPermissionStatus.denied) {
      _showPermissionDeniedDialog();
    } else if (status == LocationPermissionStatus.deniedForever) {
      _showPermissionPermanentlyDeniedDialog();
    }
  }

  void _showServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('location_services_disabled'.tr(ref)),
        content: Text('enable_location_services'.tr(ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(ref)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: Text('open_settings'.tr(ref)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('location_permission_required'.tr(ref)),
        content: Text('location_permission_message'.tr(ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(ref)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            child: Text('try_again'.tr(ref)),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('location_permission_required'.tr(ref)),
        content: Text('location_permission_denied'.tr(ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(ref)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text('open_settings'.tr(ref)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await LocationHelper.getCurrentPosition();
      if (position != null) {
        final address = await LocationHelper.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (mounted) {
          setState(() {
            _currentAddress = address;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentAddress = 'Location Unavailable';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Error getting location';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedPlots = ref.watch(savedPlotsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'BhuMitra',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcome_back'.tr(ref),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final userProfile = ref.watch(userProfileProvider);
                    return Text(
                      userProfile.name.isNotEmpty ? userProfile.name : 'Farmer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentAddress,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.grey, // Background color for the body
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: Container(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor, // Actual background color
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Measure Land Card
                        _buildMeasureCard(context),

                        const SizedBox(height: 24),

                        Text(
                          'quick_actions'.tr(ref),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Quick action grid
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.bookmark,
                                label: 'saved_plots'.tr(ref),
                                count: savedPlots.length.toString(),
                                color: const Color(0xFF2E7D32),
                                onTap: () => context.push('/saved'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.swap_horiz,
                                label: 'unit_converter'.tr(ref),
                                count: '',
                                color: const Color(0xFF1976D2),
                                onTap: () => context.push('/converter'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Help Card
                        _QuickActionCard(
                          icon: Icons.help_outline,
                          label: 'help'.tr(ref),
                          count: '',
                          color: const Color(0xFF7B1FA2),
                          onTap: () => context.push('/help'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43A047).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.landscape,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      'gps_accuracy'.tr(ref),
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E7D32),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'start_measuring'.tr(ref),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'mark_boundaries'.tr(ref),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/boundary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'measure_now'.tr(ref),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer(
            builder: (context, ref, child) {
              final userProfile = ref.watch(userProfileProvider);
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF2E7D32)),
                accountName: Text(
                  userProfile.name.isNotEmpty ? userProfile.name : 'Farmer',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(userProfile.email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    getInitials(userProfile.name),
                    style: TextStyle(fontSize: 24, color: Colors.grey[800]),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text('home'.tr(ref)),
            selected: true,
            selectedColor: const Color(0xFF2E7D32),
            onTap: () => context.pop(),
          ),

          const Divider(),
          // Language Selector
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('select_language'.tr(ref)),
            trailing: DropdownButton<String>(
              value: ref.watch(localeProvider).languageCode,
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(newValue));
                }
              },
            ),
          ),

          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text('send_feedback'.tr(ref)),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('about'.tr(ref)),
            onTap: () {
              context.pop();
              context.push('/about');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('profile'.tr(ref)),
            onTap: () {
              context.pop();
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text('settings'.tr(ref)),
            onTap: () {
              context.pop();
              context.push('/settings');
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            if (count.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String getInitials(String name) {
  if (name.trim().isEmpty) return "F";

  List<String> parts = name.trim().split(RegExp(r"\s+")); // split by space(s)

  if (parts.length == 1) {
    // Only first name
    return parts[0][0].toUpperCase();
  } else {
    // First + last
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
