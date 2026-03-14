import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.buttonIcon,
    this.onAddTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final IconData? buttonIcon;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.1),
                border:
                    Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: customColors.textMuted,
                height: 1.5,
              ),
            ),
            if (buttonText != null && onAddTap != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAddTap,
                icon: Icon(buttonIcon ?? Icons.add, color: colorScheme.onPrimary),
                label: Text(
                  buttonText!,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
