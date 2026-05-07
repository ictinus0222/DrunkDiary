import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SearchResultSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isEmpty;

  const SearchResultSection({
    super.key,
    required this.title,
    required this.children,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty || children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white38,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
