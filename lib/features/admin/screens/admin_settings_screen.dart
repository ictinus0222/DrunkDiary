import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/flags/feature_flags.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Admin Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildFlagTile(BuildContext context, String title, String subtitle,
      bool value, String key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        value: value,
        activeColor: Colors.amber,
        onChanged: (newValue) async {
          try {
            await FirebaseFirestore.instance
                .collection('configs')
                .doc('app_flags')
                .set({key: newValue}, SetOptions(merge: true));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update flag')),
            );
          }
        },
      ),
    );
  }
}
