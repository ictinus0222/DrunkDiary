import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/reaction_config.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../../drink_logs/providers/drink_logs_provider.dart';
import '../providers/activity_providers.dart';
import '../models/day_activity_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../../drink_logs/widgets/cheers_button.dart';
import '../../../core/providers/common_providers.dart';

class ActivityDetailViewer extends ConsumerStatefulWidget {
  final String activityId;
  final List<DrinkLogModel> initialLogs;
  final DateTime date;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final int initialPageIndex;

  const ActivityDetailViewer({
    super.key,
    required this.activityId,
    required this.initialLogs,
    required this.date,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    this.initialPageIndex = 0,
  });

  @override
  ConsumerState<ActivityDetailViewer> createState() => _ActivityDetailViewerState();
}

class _ActivityDetailViewerState extends ConsumerState<ActivityDetailViewer> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPageIndex;
    _pageController = PageController(initialPage: widget.initialPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.initialLogs[_currentPage];
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ── 🔝 TOP BAR (SOLID) ──────────────────────────────────────────────
          Container(
            color: customColors.deepCardBackground,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 8, // Added bottom padding to increase height slightly
            ),
            child: _TopBar(
              username: widget.username,
              userPhotoUrl: widget.userPhotoUrl,
              userId: widget.userId,
              date: widget.date,
              currentPage: _currentPage + 1,
              totalPages: widget.initialLogs.length,
              onClose: () => Navigator.pop(context),
            ),
          ),

          // ── 🖼 MEDIA AREA (EXPANDED) ────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: widget.initialLogs.length,
                  itemBuilder: (context, index) {
                    final l = widget.initialLogs[index];
                    return _MediaPage(log: l);
                  },
                ),
                
                // Note & Alcohol Type Overlay (Bottom Left of Media)
                // This stays as an overlay because it's part of the photo story
                Positioned(
                  bottom: 20,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: _ActivityOverlay(log: log),
                ),
              ],
            ),
          ),

          // ── 📊 SOCIAL INTERACTION AREA (SOLID) ──────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, 
              AppSpacing.md, 
              AppSpacing.lg, 
              MediaQuery.of(context).padding.bottom + 8
            ),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              border: Border(top: BorderSide(color: customColors.borderDark)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Social Stats (Avatars + Count + Time)
                _SocialStatsRow(
                  activityId: widget.activityId,
                  time: log.createdAt,
                ),
                const SizedBox(height: 20),
                
                // Action Buttons (Cheers, Share)
                _ActionButtonsRow(
                  activityId: widget.activityId,
                  activityOwnerId: widget.userId,
                  activityDate: widget.date,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPage extends ConsumerWidget {
  final DrinkLogModel log;
  const _MediaPage({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no user photo, try to get the alcohol catalog image
    if (log.photoUrl == null || log.photoUrl!.isEmpty) {
      if (log.alcoholId != null) {
        final alcoholAsync = ref.watch(alcoholCacheProvider(log.alcoholId!));
        return alcoholAsync.when(
          data: (alcohol) {
            if (alcohol != null && alcohol.imageUrl.isNotEmpty) {
              return _ImageWithBlurredBackground(imageUrl: alcohol.imageUrl);
            }
            return _FallbackMedia(log: log);
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
          error: (_, __) => _FallbackMedia(log: log),
        );
      }
      return _FallbackMedia(log: log);
    }

    return _ImageWithBlurredBackground(imageUrl: log.photoUrl!);
  }
}

class _ImageWithBlurredBackground extends StatelessWidget {
  final String imageUrl;
  const _ImageWithBlurredBackground({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── 🌫 BLURRED BACKGROUND ───────────────────────────────────────────
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            memCacheWidth: 150,
            color: Colors.black.withOpacity(0.4),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ColorFilters.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),

        // ── 🖼 ORIGINAL IMAGE ───────────────────────────────────────────────
        InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain, // Original aspect ratio preserved
              width: double.infinity,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper extension for easier blur (not strictly needed but cleaner)
extension ColorFilters on BackdropFilter {
  static ImageFilter blur({required double sigmaX, required double sigmaY}) {
    return ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY);
  }
}

class _FallbackMedia extends StatelessWidget {
  final DrinkLogModel log;
  const _FallbackMedia({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_bar, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(log.alcoholName, style: AppTextStyles.title.copyWith(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String username;
  final String? userPhotoUrl;
  final String userId;
  final DateTime date;
  final int currentPage;
  final int totalPages;
  final VoidCallback onClose;

  const _TopBar({
    required this.username,
    this.userPhotoUrl,
    required this.userId,
    required this.date,
    required this.currentPage,
    required this.totalPages,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
            onPressed: onClose,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)));
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.amber,
                  backgroundImage: userPhotoUrl != null ? CachedNetworkImageProvider(userPhotoUrl!) : null,
                  child: userPhotoUrl == null ? const Icon(Icons.person, size: 20, color: Colors.black) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(formattedDate, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          if (totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
              child: Text(
                '$currentPage of $totalPages',
                style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }
}

class _ActivityOverlay extends StatelessWidget {
  final DrinkLogModel log;
  const _ActivityOverlay({required this.log});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (log.note != null && log.note!.isNotEmpty)
          Text(
            log.note!,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
              shadows: [const Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2))],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.alcoholName, // Bottle name where category was
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      shadows: [const Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  if (log.logKind == LogKind.review && log.rating != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            log.rating!.toStringAsFixed(1),
                            style: AppTextStyles.body.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (log.reaction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            ReactionConfig.getIcon(log.reaction!),
                            color: ReactionConfig.getColor(log.reaction!),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            log.reaction!.name.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: ReactionConfig.getColor(log.reaction!),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              log.alcoholType.toUpperCase(), // Category moved to the right
              style: AppTextStyles.caption.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialStatsRow extends ConsumerWidget {
  final String activityId;
  final DateTime time;

  const _SocialStatsRow({required this.activityId, required this.time});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(dayActivityProvider(activityId));

    return activityAsync.when(
      data: (activity) {
        final count = activity?.cheersCount ?? 0;
        final avatars = activity?.cheerAvatars ?? [];
        
        return Row(
          children: [
            if (count > 0) ...[
              _StackedAvatars(avatars: avatars),
              const SizedBox(width: 8),
              Text(
                '$count ${count == 1 ? 'cheer' : 'cheers'}',
                style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ] else
              Text(
                'No cheers yet',
                style: AppTextStyles.body.copyWith(color: Colors.white54),
              ),
            const Spacer(),
            Text(
              DateFormat('h:mm a').format(time),
              style: AppTextStyles.caption.copyWith(color: Colors.white54, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 24),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StackedAvatars extends StatelessWidget {
  final List<String> avatars;
  const _StackedAvatars({required this.avatars});

  @override
  Widget build(BuildContext context) {
    final itemsToShow = avatars.take(3).toList();
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return SizedBox(
      width: 24.0 + (itemsToShow.length - 1) * 12.0,
      height: 24,
      child: Stack(
        children: List.generate(itemsToShow.length, (index) {
          return Positioned(
            left: index * 12.0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: customColors.cardBackground, width: 2),
                color: Colors.amber,
                image: itemsToShow[index].isNotEmpty 
                    ? DecorationImage(
                        image: ResizeImage(CachedNetworkImageProvider(itemsToShow[index]), width: 100, height: 100),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: itemsToShow[index].isEmpty 
                  ? const Icon(Icons.person, size: 12, color: Colors.black)
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  final String activityId;
  final String activityOwnerId;
  final DateTime activityDate;

  const _ActionButtonsRow({
    required this.activityId,
    required this.activityOwnerId,
    required this.activityDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CheersButton(
          activityId: activityId,
          activityOwnerId: activityOwnerId,
          activityDate: activityDate,
          isImmersive: true,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.ios_share, color: Colors.white70),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _RoundedActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundedActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

