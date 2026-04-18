import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../constants/app_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool isDiaryScreen;

  const CustomAppBar({
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.isDiaryScreen = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg), // 16px from top safe area
        child: titleWidget ??
            (isDiaryScreen
                ? SvgPicture.asset(
                    'assets/icons/drunk_diary_logo.svg',
                    height: APP_BAR_VISUAL_HEIGHT,
                  )
                : (title != null
                    ? Transform.translate(
                        offset: const Offset(0, 1), // Optically center the text
                        child: Text(
                          title!.toUpperCase(),
                          style: AppTextStyles.appBarTitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )
                    : null)),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64); // Increased height to accommodate top padding comfortably
}
