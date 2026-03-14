import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/flags/feature_flags.dart';

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
            // Add future flags here
          ],
        ),
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (err, stack) => Center(
            child:
                Text('Error: $err', style: TextStyle(color: colorScheme.error))),
      ),
    );
  }
}
