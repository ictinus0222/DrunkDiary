import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/flags/feature_flags.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/theme/app_spacing.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(featureFlagsProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Admin Settings'),
      body: flagsAsync.when(
        data: (flags) => ListView(
          padding: AppSpacing.pagePadding,
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
