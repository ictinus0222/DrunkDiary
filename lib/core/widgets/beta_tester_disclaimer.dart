import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/screenshot_provider.dart';
import '../../features/profile/widgets/feedback_bottom_sheet.dart';

class BetaTesterDisclaimer extends ConsumerWidget {
  final String currentScreen;
  const BetaTesterDisclaimer({super.key, required this.currentScreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCapturing = ref.watch(feedbackScreenshotInProgressProvider);
    if (isCapturing) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Colors.amber,
          iconColor: Colors.amber,
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(
            'BETA PREVIEW & FEEDBACK',
            style: TextStyle(
              color: Colors.amber.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                children: [
                  Text(
                    'Thank you for being an early DrunkDiary tester! Your feedback directly shapes the future of this collection.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Hide disclaimer before capture
                      ref.read(feedbackScreenshotInProgressProvider.notifier).set(true);
                      
                      // Wait for UI to update
                      await Future.delayed(const Duration(milliseconds: 100));

                      // Capture Screenshot
                      final controller = ref.read(screenshotControllerProvider);
                      final imageBytes = await controller.capture();
                      
                      // Show disclaimer again
                      ref.read(feedbackScreenshotInProgressProvider.notifier).set(false);
                      
                      File? screenshotFile;
                      if (imageBytes != null) {
                        final tempDir = await getTemporaryDirectory();
                        screenshotFile = await File('${tempDir.path}/feedback_${DateTime.now().millisecondsSinceEpoch}.png').create();
                        await screenshotFile.writeAsBytes(imageBytes);
                      }

                      if (context.mounted) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => FeedbackBottomSheet(
                            currentScreen: currentScreen,
                            initialScreenshot: screenshotFile,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('SHARE FEEDBACK'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/icons/play_store_512.png',
                      height: 24,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
