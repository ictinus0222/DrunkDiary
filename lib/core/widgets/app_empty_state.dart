import 'package:flutter/material.dart';

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
                color: Colors.amber.withOpacity(0.1),
                border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
              ),
              child: Icon(
                icon,
                color: Colors.amber,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (buttonText != null && onAddTap != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAddTap,
                icon: Icon(buttonIcon ?? Icons.add, color: Colors.black),
                label: Text(
                  buttonText!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

