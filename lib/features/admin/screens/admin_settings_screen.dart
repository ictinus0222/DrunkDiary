import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/flags/feature_flags.dart';
import '../../../app/app_theme.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Settings',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: flagsAsync.when(
        data: (flags) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFlagTile(
              context,
              'Personal Meaning Section',
              'Toggles the "What this means to you" section in alcohol details.',
              flags.personalMeaningEnabled,
              'personal_meaning_enabled',
            ),
          ],
        ),
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (err, stack) => Center(
            child:
                Text('Error: $err', style: TextStyle(color: colorScheme.error))),
      ),
    );
  }

  Widget _buildFlagTile(BuildContext context, String title, String subtitle,
      bool value, String key) {
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: customColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: textTheme.bodySmall?.copyWith(color: customColors.textMuted)),
        value: value,
        activeColor: colorScheme.primary,
        onChanged: (newValue) async {
          try {
            await FirebaseFirestore.instance
                .collection('configs')
                .doc('app_flags')
                .set({key: newValue}, SetOptions(merge: true));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update flag', style: TextStyle(color: colorScheme.onError)),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
      ),
    );
  }
}
