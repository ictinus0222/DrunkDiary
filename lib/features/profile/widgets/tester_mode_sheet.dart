import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_environment.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TesterModeSheet extends ConsumerWidget {
  const TesterModeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusDefault)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tester Mode', style: AppTextStyles.title),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildInfoRow('Environment', AnalyticsConfig.current.name.toUpperCase()),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return Column(
                children: [
                  _buildInfoRow('Version', snapshot.data!.version),
                  _buildInfoRow('Build', snapshot.data!.buildNumber),
                ],
              );
            },
          ),
          
          const Divider(height: 32, color: Colors.white12),
          
          Text('Debug Tools', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: AppSpacing.md),
          
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.redAccent),
            title: const Text('Force Crash (Test)'),
            onTap: () => throw Exception('Tester Mode: Manual Crash'),
          ),
          
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.blueAccent),
            title: const Text('Clear Local Cache'),
            onTap: () {
              // Implementation placeholder
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
            },
          ),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
