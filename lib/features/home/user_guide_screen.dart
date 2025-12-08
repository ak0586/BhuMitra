import 'package:bhumitra/core/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserGuideScreen extends ConsumerWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text('user_guide'.tr(ref)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Introduction
          _buildSection(
            context,
            ref,
            'introduction',
            'introduction_desc',
            Icons.info_outline,
            Colors.blue,
          ),

          const SizedBox(height: 16),

          // Getting Started
          _buildSection(
            context,
            ref,
            'getting_started',
            'getting_started_desc',
            Icons.rocket_launch,
            Colors.green,
          ),

          const SizedBox(height: 16),

          // Step-by-step Guide
          _buildStepByStepGuide(context, ref),

          const SizedBox(height: 16),

          // Tips & Best Practices
          _buildSection(
            context,
            ref,
            'tips_best_practices',
            'tips_desc',
            Icons.lightbulb_outline,
            Colors.orange,
          ),

          const SizedBox(height: 16),

          // Troubleshooting
          _buildSection(
            context,
            ref,
            'troubleshooting',
            'troubleshooting_desc',
            Icons.build,
            Colors.red,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    String titleKey,
    String contentKey,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titleKey.tr(ref),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              contentKey.tr(ref),
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepByStepGuide(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.format_list_numbered,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'step_by_step_guide'.tr(ref),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStep(ref, 1, 'step1_title', 'step1_desc'),
                const SizedBox(height: 16),
                _buildStep(ref, 2, 'step2_title', 'step2_desc'),
                const SizedBox(height: 16),
                _buildStep(ref, 3, 'step3_title', 'step3_desc'),
                const SizedBox(height: 16),
                _buildStep(ref, 4, 'step4_title', 'step4_desc'),
                const SizedBox(height: 16),
                _buildStep(ref, 5, 'step5_title', 'step5_desc'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    WidgetRef ref,
    int number,
    String titleKey,
    String descKey,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleKey.tr(ref),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descKey.tr(ref),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
