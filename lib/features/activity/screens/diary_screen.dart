import 'package:drunk_diary/core/widgets/beta_tester_disclaimer.dart';
import 'dart:math';
import 'package:drunk_diary/app/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_model_dto.dart';
import 'package:flutter/material.dart';

import '../../drink_logs/widgets/drink_log_card.dart';
import '../../drink_logs/widgets/day_section.dart';
import '../../drink_logs/widgets/log_detail_bottom_sheet.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../../core/widgets/app_empty_state.dart';
import 'package:drunk_diary/core/navigation/tab_change_notification.dart';
import '../../../app/app_theme.dart';
import 'package:drunk_diary/features/drink_logs/providers/drink_logs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/notifications_provider.dart';
import '../../profile/providers/profile_providers.dart';
import '../../profile/models/user_model.dart';
import '../../../core/theme/responsive_tokens.dart';
import '../../../core/theme/app_typography_roles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_layout.dart';

enum DiaryLayout { timeline, gallery }

class DiaryScreen extends ConsumerStatefulWidget {
  static const routeName = '/diary';
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  String _selectedFilter = 'All';
  DiaryLayout _currentLayout = DiaryLayout.timeline;

  @override
  Widget build(BuildContext context) {
    final logsAsync = _selectedFilter == 'All' 
        ? ref.watch(filteredAllDrinkLogsProvider) 
        : _selectedFilter == 'Friends'
            ? ref.watch(friendsFeedProvider)
            : ref.watch(drinkLogsProvider);

    return SafeArea(
      child: logsAsync.when(
        loading: () => Scaffold(
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                centerTitle: true,
                leading: const _ProfileAvatarLeading(),
                leadingWidth: 64,
                title: SvgPicture.asset(
                  'assets/icons/drunk_diary_logo.svg',
                  height: APP_BAR_VISUAL_HEIGHT,
                  placeholderBuilder: (_) => const SizedBox.shrink(),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _NotificationBadgeButton(),
                  ),
                ],
              ),
              const SliverToBoxAdapter(child: _WelcomeSectionSkeleton()),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      AppShimmer(width: 100, height: 36, borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: AppSpacing.sm),
                      AppShimmer(width: 80, height: 36, borderRadius: BorderRadius.circular(20)),
                      const SizedBox(width: AppSpacing.sm),
                      AppShimmer(width: 110, height: 36, borderRadius: BorderRadius.circular(20)),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              _DiarySliverListSkeleton(layout: _currentLayout),
            ],
          ),
        ),
        error: (err, stack) => Scaffold(
          body: Center(child: Text('Error: $err')),
        ),
        data: (allLogs) {
          final logs = allLogs.where((log) {
            if (_selectedFilter == 'All') return true;
            if (_selectedFilter == 'Logs') return log.logKind == LogKind.log;
            if (_selectedFilter == 'Reviews') {
              return log.logKind == LogKind.review;
            }
            return true;
          }).toList();

          return Scaffold(
            body: ResponsiveScaffoldBody(
              maxWidth: AppWidths.feed,
              padding: EdgeInsets.zero,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    centerTitle: true,
                    leading: const _ProfileAvatarLeading(),
                    leadingWidth: 64,
                    title: SvgPicture.asset(
                      'assets/icons/drunk_diary_logo.svg',
                      height: APP_BAR_VISUAL_HEIGHT,
                      placeholderBuilder: (_) => const SizedBox.shrink(),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _NotificationBadgeButton(),
                      ),
                    ],
                  ),
                  const SliverToBoxAdapter(child: _WelcomeSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
                  SliverToBoxAdapter(
                    child: _FiltersRow(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
                  _DiarySliverList(
                    logs: logs,
                    layout: _currentLayout,
                    selectedFilter: _selectedFilter,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.hero)),
                ],
              ),
            ),
            bottomNavigationBar: const BetaTesterDisclaimer(currentScreen: 'Diary'),
          );
        },
      ),
    );
  }
}

/* ----------------------------- WELCOME SECTION ----------------------------- */

class _WelcomeSection extends StatefulWidget {
  const _WelcomeSection();

  @override
  State<_WelcomeSection> createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends State<_WelcomeSection> {
  late String _greeting;

  final List<String> _morningGreetings = [
    'Coffee or a breakfast brew?',
    'What\'s the early pour?',
    'Ready for the day\'s first log?',
    'Morning! Starting fresh?',
    'The morning after?',
    'Hydration (with flavor)?',
    'A little \'hair of the dog\'?',
    'Quiet morning, loud bottle.',
  ];

  final List<String> _afternoonGreetings = [
    'What are we drinking?',
    'Found anything new?',
    'A midday refreshment?',
    'Time to log a memory?',
    'Is it 5 PM yet?',
    'A sip of sophistication?',
    'Whatever floats your bottle.',
    'Sip happens.',
    'Found a liquid treasure?',
  ];

  final List<String> _eveningGreetings = [
    'Recording a night to remember?',
    'What\'s the poison tonight?',
    'Sipping on something special?',
    'Ready for another round?',
    'Working on your collection?',
    'Blurry nights, clear memories?',
    'Drunk on life, or just Gin?',
    'Tasting notes: Liquid regret?',
    'Another day, another pour.',
    'Sip, log, repeat.',
    'Fuel for the story.',
    'A toast to the moon.',
    'Sipping with style.',
    'Your cabinet is calling.',
  ];

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = _morningGreetings[Random().nextInt(_morningGreetings.length)];
    } else if (hour < 17) {
      _greeting = _afternoonGreetings[Random().nextInt(_afternoonGreetings.length)];
    } else {
      _greeting = _eveningGreetings[Random().nextInt(_eveningGreetings.length)];
    }
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _greeting,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'GiveYouGlory',
                    fontSize: 32,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/* ----------------------------- FILTERS ----------------------------- */

class _FiltersRow extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const _FiltersRow({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                    _FilterChip(
                      label: 'All Activity',
                      selected: selectedFilter == 'All',
                      onTap: () => onFilterChanged('All'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _FilterChip(
                      label: 'Friends',
                      selected: selectedFilter == 'Friends',
                      onTap: () => onFilterChanged('Friends'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _FilterChip(
                      label: 'Your Logs',
                      selected: selectedFilter == 'Logs',
                      onTap: () => onFilterChanged('Logs'),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  _FilterChip(
                    label: 'Your Reviews',
                    selected: selectedFilter == 'Reviews',
                    onTap: () => onFilterChanged('Reviews'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border:
              Border.all(color: selected ? Colors.amber : customColors.borderDark),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: selected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- DIARY SLIVERS ----------------------------- */

class _DiarySliverList extends StatelessWidget {
  final List<DrinkLogModel> logs;
  final DiaryLayout layout;
  final String selectedFilter;

  const _DiarySliverList({
    required this.logs,
    required this.layout,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      final isFriendsFeed = selectedFilter == 'Friends';
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: isFriendsFeed ? Icons.people_outline_rounded : Icons.history_edu_outlined,
          title: isFriendsFeed ? 'No friend activity yet' : 'Your diary is empty',
          subtitle: isFriendsFeed 
              ? 'Add friends to see their diary entries,\nratings, and drinking memories here.'
              : 'Capture your first drink memory\nand see it here.',
          buttonText: isFriendsFeed ? 'Find Friends' : 'Log a Drink',
          onAddTap: () {
            if (isFriendsFeed) {
              const TabChangeNotification(1).dispatch(context); // Discover tab
            } else {
              const TabChangeNotification(2).dispatch(context); // Log tab
            }
          },
        ),
      );
    }

    if (layout == DiaryLayout.gallery) {
      return SliverResponsiveConstrainedBox(
        maxWidth: AppWidths.grid,
        padding: AppSpacing.pagePadding.copyWith(top: 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _GalleryItem(log: logs[index]),
            childCount: logs.length,
          ),
        ),
      );
    }

    // Group logs by date and user
    final activityGroups = _groupLogsByDateAndUser(logs);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final group = activityGroups[index];
          return DayActivityCard(
            date: group.date,
            logs: group.logs,
          );
        },
        childCount: activityGroups.length,
      ),
    );
  }

  List<ActivityGroup> _groupLogsByDateAndUser(List<DrinkLogModel> logs) {
    final Map<String, List<DrinkLogModel>> grouped = {};

    for (final log in logs) {
      final date = log.createdAt.toLocal();
      final dayStart = DateTime(date.year, date.month, date.day);
      // Create a unique key for each user per day
      final key = "${dayStart.toIso8601String()}_${log.userId}";
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(log);
    }
    
    final groups = grouped.values.map((logsInGroup) {
      final firstLog = logsInGroup.first;
      final date = firstLog.createdAt.toLocal();
      final dayStart = DateTime(date.year, date.month, date.day);
      return ActivityGroup(
        date: dayStart,
        userId: firstLog.userId,
        logs: logsInGroup,
      );
    }).toList();

    // Sort by date descending
    groups.sort((a, b) => b.date.compareTo(a.date));
      
    return groups;
  }
}

class ActivityGroup {
  final DateTime date;
  final String userId;
  final List<DrinkLogModel> logs;

  ActivityGroup({
    required this.date,
    required this.userId,
    required this.logs,
  });
}



class _GalleryItem extends ConsumerWidget {
  final DrinkLogModel log;
  const _GalleryItem({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    return GestureDetector(
      onTap: () {
        // reuse same detail view as card
        showModalBottomSheet(
          context: context,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => LogDetailBottomSheet(log: log),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          gradient: AppColors.getAlcoholGradient(log.alcoholType),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: log.photoUrl != null && log.photoUrl!.isNotEmpty
                  ? Hero(
                      tag: 'alcohol_${log.id}_photo',
                      child: CachedNetworkImage(
                        imageUrl: log.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const AppShimmer(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    )
                      : (log.alcoholId == null
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.getAlcoholGradient(log.alcoholType),
                              ),
                              child: const Icon(Icons.local_bar, color: Colors.white24),
                            )
                          : ref.watch(alcoholCacheProvider(log.alcoholId!)).when(
                              data: (alcohol) {
                                if (alcohol == null) {
                                  return Container(
                                    color: customColors.borderDark,
                                    child: const Icon(Icons.local_bar, color: Colors.white24),
                                  );
                                }
                                return Hero(
                                  tag: 'alcohol_log_${log.id}',
                                  child: CachedNetworkImage(
                                    imageUrl: alcohol.imageUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 300, // Gallery items are roughly 1/2 screen width
                                    placeholder: (context, url) => const AppShimmer(),
                                    errorWidget: (context, url, error) => Container(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.getAlcoholGradient(log.alcoholType),
                                      ),
                                      child: const Icon(Icons.local_bar, color: Colors.white24),
                                    ),
                                  ),
                                );
                              },
                              loading: () => Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.getAlcoholGradient(log.alcoholType),
                                ),
                                child: const Center(child: AppShimmer()),
                              ),
                              error: (_, __) => Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.getAlcoholGradient(log.alcoholType),
                                ),
                                child: const Icon(Icons.local_bar, color: Colors.white24),
                              ),
                            )),
            ),

            // Gradient Overlay for visibility
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            // Title at bottom
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Text(
                log.alcoholName,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/* ----------------------------- SKELETONS ----------------------------- */

class _WelcomeSectionSkeleton extends StatelessWidget {
  const _WelcomeSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppShimmer(width: 250, height: 36, borderRadius: BorderRadius.all(Radius.circular(12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiarySliverListSkeleton extends StatelessWidget {
  final DiaryLayout layout;
  const _DiarySliverListSkeleton({required this.layout});

  @override
  Widget build(BuildContext context) {
    if (layout == DiaryLayout.gallery) {
      return SliverPadding(
        padding: AppSpacing.pagePadding.copyWith(top: 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => AppShimmer(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              height: double.infinity,
            ),
            childCount: 6,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index % 4 == 0) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.sm),
              child: AppShimmer(width: 80, height: 12),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: AppShimmer(
              height: 140,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
          );
        },
        childCount: 10,
      ),
    );
  }
}

class _NotificationBadgeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.notifications),
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
/* ----------------------------- WIDGETS & HELPERS --------------------------- */

class _ProfileAvatarLeading extends ConsumerWidget {
  const _ProfileAvatarLeading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDataProvider);

    return GestureDetector(
      onTap: () {
        const TabChangeNotification(4).dispatch(context);
      },
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10, width: 1.5),
            ),
            child: ClipOval(
              child: profileAsync.when(
                data: (profile) {
                  final photoUrl = profile?.userData.photoUrl;
                  if (photoUrl != null && photoUrl.isNotEmpty) {
                    return CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const AppShimmer(),
                      errorWidget: (_, __, ___) => const Icon(Icons.person, size: 20, color: Colors.white24),
                    );
                  }
                  return const Icon(Icons.person, size: 20, color: Colors.white24);
                },
                loading: () => const AppShimmer(),
                error: (_, __) => const Icon(Icons.person, size: 20, color: Colors.white24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
