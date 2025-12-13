import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('about'.tr(ref))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.landscape, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'app_name'.tr(ref),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${'version'.tr(ref)} 1.0.0',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'about'.tr(ref),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'about_description'.tr(ref),
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'features'.tr(ref),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildFeature(Icons.gps_fixed, 'gps_measurement'.tr(ref)),
                    _buildFeature(Icons.save, 'save_manage_plots'.tr(ref)),
                    _buildFeature(Icons.swap_horiz, 'unit_converter'.tr(ref)),
                    _buildFeature(Icons.language, 'multi_language'.tr(ref)),
                    _buildFeature(
                      Icons.cloud_off,
                      'offline_mode_feature'.tr(ref),
                    ),
                    _buildFeature(Icons.dark_mode, 'dark_mode_feature'.tr(ref)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Color(0xFF2E7D32),
                ),
                title: Text('privacy_policy'.tr(ref)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final Uri url = Uri.parse(
                    'https://ak0586.github.io/BhuMitra/index.html',
                  );
                  if (!await launchUrl(url)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not launch privacy policy'),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            Text(
              'copyright'.tr(ref),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
