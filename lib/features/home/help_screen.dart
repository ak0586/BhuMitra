import 'package:bhumitra/core/localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhumitra/main.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_guide_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ad_manager.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  int? _expandedIndex;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = AdManager().loadNativeAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isNativeAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isNativeAdLoaded = false;
            _nativeAd?.dispose();
            _nativeAd = null;
          });
        }
      },
    );
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

  //Function to launch the email app
  Future<void> _launchFeedbackEmail([String? query]) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'ankitraj81919895@gmail.com',
      query: 'subject=${query ?? 'BhuMitra Feedback'}',
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch email app')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email app')),
        );
      }
    }
  }

  // Function to launch the dialer
  Future<void> _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    // Use launchUrl to safely attempt opening the URI
    if (await launchUrl(launchUri)) {
      // The OS will open the dialer with the number pre-filled
    } else {
      // Handle the case where the URL couldn't be launched (e.g., on a desktop emulator without phone support)
      // You could show a SnackBar or AlertDialog here
      print('Could not launch $launchUri');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build FAQs dynamically from translations
    final List<FAQItem> _faqs = [
      FAQItem(
        question: 'faq_mark_boundaries_q'.tr(ref),
        answer: 'faq_mark_boundaries_a'.tr(ref),
      ),
      FAQItem(
        question: 'faq_area_units_q'.tr(ref),
        answer: 'faq_area_units_a'.tr(ref),
      ),
      FAQItem(
        question: 'faq_save_measurements_q'.tr(ref),
        answer: 'faq_save_measurements_a'.tr(ref),
      ),
      FAQItem(
        question: 'faq_gps_accuracy_q'.tr(ref),
        answer: 'faq_gps_accuracy_a'.tr(ref),
      ),
      FAQItem(
        question: 'faq_custom_units_q'.tr(ref),
        answer: 'faq_custom_units_a'.tr(ref),
      ),
      // FAQItem(
      //   question: 'faq_offline_mode_q'.tr(ref),
      //   answer: 'faq_offline_mode_a'.tr(ref),
      // ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text('help_support'.tr(ref)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // FAQ Section
                Text(
                  'faqs'.tr(ref),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // FAQ Accordion
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: List.generate(_faqs.length, (index) {
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          _buildFAQItem(_faqs[index], index),
                        ],
                      );
                    }),
                  ),
                ),

                // Native Ad
                if (_isNativeAdLoaded && _nativeAd != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    height: 120, // Adjust height based on template
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AdWidget(ad: _nativeAd!),
                  ),
                ],

                const SizedBox(height: 24),

                // Video Tutorial Card
                _buildVideoTutorialCard(),

                const SizedBox(height: 24),

                // Contact Support
                Text(
                  'contact_support'.tr(ref),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

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
                                ? Colors.blue[900]!.withOpacity(0.3)
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.email, color: Colors.blue),
                        ),
                        title: Text('email'.tr(ref)),
                        subtitle: const Text('ankitraj81919895@gmail.com'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.pop();
                          _launchFeedbackEmail('Support');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.green[900]!.withOpacity(0.3)
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.phone, color: Colors.green),
                        ),
                        title: Text('phone'.tr(ref)),
                        subtitle: const Text('+91 8851587898'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.pop();
                          _launchDialer('+91 8851587898');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.orange[900]!.withOpacity(0.3)
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.feedback,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text('send_feedback'.tr(ref)),
                        subtitle: Text('help_us_improve'.tr(ref)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.pop();
                          _launchFeedbackEmail();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // User Guide Button
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/user-guide'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(
                        color: Color(0xFF2E7D32),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.book),
                    label: Text(
                      'view_user_guide'.tr(ref),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
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

  Widget _buildFAQItem(FAQItem faq, int index) {
    final isExpanded = _expandedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                faq.answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTutorialCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'video_tutorials'.tr(ref),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'how_to_use_bhumitra'.tr(ref),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'watch_step_by_step'.tr(ref),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('watch_tutorial'.tr(ref)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
