import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/preferences.dart';
import '../../core/localization.dart';
import '../../core/ad_manager.dart';

// Simple state providers (not persisted)
// Simple state providers (not persisted)

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('settings'.tr(ref)), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // General Settings
                _SectionHeader(title: 'general_settings'.tr(ref)),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildPreferenceTile(
                        context,
                        ref,
                        Icons.dark_mode,
                        'dark_mode'.tr(ref),
                        'dark_mode_desc'.tr(ref),
                        darkModeProvider,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Map Settings
                _SectionHeader(title: 'map_settings'.tr(ref)),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDropdownTile(
                        context,
                        ref,
                        Icons.map,
                        'map_type'.tr(ref),
                        mapTypeProvider,
                        ['normal'.tr(ref), 'satellite'.tr(ref)],
                      ),
                      const Divider(height: 1),
                      _buildDropdownTile(
                        context,
                        ref,
                        Icons.straighten,
                        'default_unit'.tr(ref),
                        defaultUnitProvider,
                        [
                          'Square Feet',
                          'Square Meters',
                          'Square Yards',
                          'Acre',
                          'Hectare',
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Measurement Settings
                _SectionHeader(title: 'measurement_settings'.tr(ref)),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.precision_manufacturing,
                            color: Color(0xFF2E7D32),
                            size: 20,
                          ),
                        ),
                        title: Text('precision_level'.tr(ref)),
                        subtitle: Text(
                          '${ref.watch(precisionProvider)} decimal places',
                        ),
                        trailing: DropdownButton<int>(
                          value: ref.watch(precisionProvider),
                          underline: Container(),
                          items: [2, 4, 6].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value'),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              ref
                                  .read(precisionProvider.notifier)
                                  .setPrecision(newValue);
                            }
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        context,
                        ref,
                        Icons.save_alt,
                        'Auto-save Plots',
                        'Automatically save measurements',
                        autoSaveProvider,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Reset Button
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('reset_settings'.tr(ref)),
                        content: Text('reset_settings_confirm'.tr(ref)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('cancel'.tr(ref)),
                          ),
                          TextButton(
                            onPressed: () async {
                              // Reset all settings
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('offline_mode', false);
                              await prefs.setBool('dark_mode', false);
                              ref.read(offlineModeProvider.notifier).state =
                                  false;
                              ref.read(darkModeProvider.notifier).state = false;
                              await ref
                                  .read(mapTypeProvider.notifier)
                                  .setMapType('Normal');
                              ref
                                  .read(defaultUnitProvider.notifier)
                                  .setDefaultUnit('Square Feet');
                              ref
                                  .read(precisionProvider.notifier)
                                  .setPrecision(2);
                              ref
                                  .read(autoSaveProvider.notifier)
                                  .setAutoSave(true);
                              ref
                                  .read(localeProvider.notifier)
                                  .setLocale(const Locale('en'));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('settings_reset'.tr(ref)),
                                ),
                              );
                            },
                            child: Text('reset'.tr(ref)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text('reset_defaults'.tr(ref)),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isBannerAdLoaded && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  // For StateNotifierProvider (Dark Mode, Offline Mode)
  Widget _buildPreferenceTile(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    String subtitle,
    StateNotifierProvider<dynamic, bool> provider,
  ) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: ref.watch(provider),
      onChanged: (bool value) {
        if (provider == darkModeProvider) {
          ref.read(darkModeProvider.notifier).toggle();
        } else if (provider == offlineModeProvider) {
          ref.read(offlineModeProvider.notifier).toggle();
        }
      },
      activeColor: const Color(0xFF2E7D32),
    );
  }

  // For StateNotifierProvider (Auto Save)
  Widget _buildSwitchTile(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    String subtitle,
    StateNotifierProvider<AutoSaveNotifier, bool> provider,
  ) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: ref.watch(provider),
      onChanged: (bool value) {
        ref.read(provider.notifier).setAutoSave(value);
      },
      activeColor: const Color(0xFF2E7D32),
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    StateNotifierProvider<dynamic, String> provider,
    List<String> options,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(title),
      subtitle: Text(ref.watch(provider), style: const TextStyle(fontSize: 12)),
      trailing: DropdownButton<String>(
        value: ref.watch(provider),
        underline: Container(),
        items: options.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? newValue) async {
          if (newValue != null) {
            // Save to SharedPreferences based on provider type
            if (provider == mapTypeProvider) {
              await ref.read(mapTypeProvider.notifier).setMapType(newValue);
            } else if (provider == defaultUnitProvider) {
              await ref
                  .read(defaultUnitProvider.notifier)
                  .setDefaultUnit(newValue);
            }
          }
        },
      ),
    );
  }
}

class _SectionHeader extends ConsumerWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}
