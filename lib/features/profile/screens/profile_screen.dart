import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../../drink_logs/providers/drink_logs_provider.dart';
import '../../drink_logs/widgets/day_section.dart';
import '../providers/profile_providers.dart';
import '../models/user_model.dart';
import '../../../core/utils/visibility_resolver.dart';
import '../../../app/app_routes.dart';
import '../../../core/providers/common_providers.dart';
import '../widgets/edit_profile_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/responsive_tokens.dart';
import '../../../core/theme/app_typography_roles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_layout.dart';

class ProfileScreen extends ConsumerWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(userIdProvider);
    final isMe = userId == null || userId == currentUserId;
    final effectiveUserId = userId ?? currentUserId;

    if (effectiveUserId == null) return const Center(child: Text('Not logged in'));

    final profileAsync = isMe 
        ? ref.watch(profileDataProvider) 
        : ref.watch(otherProfileDataProvider(effectiveUserId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ResponsiveScaffoldBody(
        maxWidth: AppWidths.profile,
        padding: EdgeInsets.zero,
        child: profileAsync.when(
          skipLoadingOnRefresh: true,
          loading: () => profileAsync.hasValue 
              ? _buildProfileData(context, ref, profileAsync.value, isMe)
              : const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (profile) => _buildProfileData(context, ref, profile, isMe),
        ),
      ),
    );
  }

  Widget _buildProfileData(BuildContext context, WidgetRef ref, dynamic profile, bool isMe) {
    if (profile == null) return const Center(child: Text('No profile found'));

    final userData = profile.userData as UserModel;
    final currentUserAsync = ref.watch(profileDataProvider);
    final currentUser = currentUserAsync.value?.userData;

    if (currentUser == null) return const Center(child: CircularProgressIndicator());

    final canView = VisibilityResolver.canViewProfile(viewer: currentUser, owner: userData);
    
    if (!canView) {
      return _buildLockedProfileView(context, ref, userData, currentUser);
    }

    return _buildFullProfile(context, ref, profile, isMe);
  }

  void _selfHealUser(dynamic user) {
    FirebaseFirestore.instance.collection('users').doc(user.id).update({
      'usernameLowercase': user.username.toLowerCase(),
      'displayNameLowercase': user.displayName.toLowerCase(),
    }).catchError((e) => print('Self-heal failed: $e'));
  }

  Widget _buildLockedProfileView(BuildContext ctx, WidgetRef ref, UserModel userData, UserModel currentUser) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileHeader(
            profile: userData,
            uniqueDays: 0, // Gated
            isMe: false,
            isLocked: true,
            currentUser: currentUser,
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

        // Premium Locked Content UI
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Centered Lock Icon & Message
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        size: 64,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Private Profile',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Become friends to view diary entries,\nratings, shelf activity, and reviews.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Social Action Area
                    _buildSocialAction(ctx, ref, userData, currentUser),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.hero),
              
              // Blurred placeholders to create "Mystery"
              _buildBlurredPlaceholderSection('ACTIVITY'),
              const SizedBox(height: AppSpacing.lg),
              _buildBlurredPlaceholderCard(),
              _buildBlurredPlaceholderCard(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurredPlaceholderSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white24,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 40, color: Colors.white12),
      ],
    );
  }

  Widget _buildSocialAction(BuildContext ctx, WidgetRef ref, UserModel targetUser, UserModel currentUser) {
    if (currentUser.friends.contains(targetUser.id)) {
      return _buildActionBadge(Icons.check_circle_rounded, 'Friends', AppColors.amber);
    } else if (currentUser.pendingOutgoingRequests.contains(targetUser.id)) {
      return _buildActionBadge(Icons.hourglass_bottom_rounded, 'Friend Request Sent', Colors.white38);
    } else if (currentUser.pendingIncomingRequests.contains(targetUser.id)) {
      return _buildPrimaryAction(
        Icons.person_add_rounded,
        'Accept Friend Request',
        () => _handleAccept(ctx, ref, currentUser, targetUser),
      );
    } else if (currentUser.blockedUsers.contains(targetUser.id)) {
      return _buildActionBadge(Icons.block_rounded, 'User Blocked', Colors.white24);
    } else {
      return _buildPrimaryAction(
        Icons.person_add_rounded,
        'Add Friend to Unlock',
        () => _handleSendRequest(ctx, ref, currentUser, targetUser),
      );
    }
  }

  Widget _buildActionBadge(IconData icon, String label, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(IconData icon, String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _handleSendRequest(BuildContext context, WidgetRef ref, UserModel currentUser, UserModel targetUser) async {
    try {
      await ref.read(friendshipRepositoryProvider).sendFriendRequest(
        fromUserId: currentUser.id,
        fromUsername: currentUser.displayName,
        fromPhotoUrl: currentUser.photoUrl,
        toUserId: targetUser.id,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent to ${targetUser.displayName}')),
        );
      }
      
      ref.invalidate(profileDataProvider);
      ref.invalidate(otherProfileDataProvider(targetUser.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  Future<void> _handleAccept(BuildContext context, WidgetRef ref, UserModel currentUser, UserModel targetUser) async {
    try {
      await ref.read(friendshipRepositoryProvider).acceptFriendRequest(currentUser.id, targetUser.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accepted ${targetUser.displayName}\'s request')),
        );
      }
      
      ref.invalidate(profileDataProvider);
      ref.invalidate(otherProfileDataProvider(targetUser.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Widget _buildBlurredPlaceholderCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(
          'DIARY ENTRY HIDDEN',
          style: AppTextStyles.caption.copyWith(color: Colors.white12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFullProfile(BuildContext context, WidgetRef ref, dynamic profile, bool isMe) {
    final effectiveUserId = userId ?? ref.watch(userIdProvider);
    if (effectiveUserId == null) return const Center(child: Text('User ID missing'));

    // HARD GATING: logs provider is only watched here if the profile is NOT locked
    // (buildFullProfile is only called if isLocked is false)
    final logsAsync = ref.watch(userDrinkLogsProvider(effectiveUserId));
    
    return logsAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => logsAsync.hasValue 
          ? _buildProfileContent(context, ref, profile.userData, 
              logsAsync.value!.map((log) => DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day)).toSet().length,
              _groupLogsByDate(logsAsync.value!), isMe)
          : const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (allLogs) {
        final uniqueDays = allLogs.map((log) => DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day)).toSet().length;
        final groupedLogs = _groupLogsByDate(allLogs);
        return _buildProfileContent(context, ref, profile.userData, uniqueDays, groupedLogs, isMe);
      },
    );
  }

  Widget _buildProfileContent(
    BuildContext context, 
    WidgetRef ref, 
    dynamic userData, 
    int uniqueDays, 
    List<MapEntry<DateTime, List<DrinkLogModel>>> groupedLogs,
    bool isMe,
  ) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileHeader(
            profile: userData,
            uniqueDays: uniqueDays,
            isMe: isMe,
            currentUser: ref.watch(profileDataProvider).value?.userData,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVITY',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 2, width: 40, color: Colors.amber),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = groupedLogs[index];
              return DayActivityCard(
                date: entry.key,
                logs: entry.value,
                showUser: false,
              );
            },
            childCount: groupedLogs.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.hero)),
      ],
    );
  }

  // ── Grouping Logic (Mirror of DiaryScreen) ──────────────────────────────────

  List<MapEntry<DateTime, List<DrinkLogModel>>> _groupLogsByDate(List<DrinkLogModel> logs) {
    final Map<DateTime, List<DrinkLogModel>> grouped = {};

    for (final log in logs) {
      final date = log.createdAt.toLocal();
      final dayStart = DateTime(date.year, date.month, date.day);
      if (!grouped.containsKey(dayStart)) {
        grouped[dayStart] = [];
      }
      grouped[dayStart]!.add(log);
    }
    
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
      
    return sortedEntries;
  }
}

class _ProfileHeader extends ConsumerWidget {
  final dynamic profile;
  final int uniqueDays;
  final bool isLocked;
  final UserModel? currentUser;
  final bool isMe;

  const _ProfileHeader({
    required this.profile,
    required this.uniqueDays,
    this.isMe = true,
    this.isLocked = false,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover Image + Avatar Stack ───────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover Image
            AspectRatio(
              aspectRatio: 2.5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: customColors.cardBackground,
                ),
                child: profile.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: profile.coverUrl!,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        placeholder: (_, __) => Container(color: Colors.white10),
                        errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.white12, size: 48),
                      )
                    : const Center(child: Icon(Icons.image, color: Colors.white12, size: 48)),
              ),
            ),

            // Settings Icon
            if (isMe)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.settings),
                  ),
                ),
              )
            else
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

            // Overlapping Avatar
            Positioned(
              bottom: -40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.amber,
                  backgroundImage: profile.photoUrl != null
                      ? CachedNetworkImageProvider(profile.photoUrl!)
                      : null,
                  child: profile.photoUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.black)
                      : null,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // ── Name + Edit Row ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  profile.displayName,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              if (isMe)
                Row(
                  children: [
                    if (profile.instagram != null && profile.instagram!.isNotEmpty) ...[
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.alternate_email, color: Colors.amber, size: 18),
                          onPressed: () => _launchInstagram(context, profile.instagram!),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton(
                      onPressed: () => EditProfileSheet.show(context, profile),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: customColors.borderDark),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Edit"),
                    ),
                  ],
                ),
              if (!isMe && currentUser != null)
                _buildFriendshipAction(context, ref),
            ],
          ),
        ),

        // ── Username ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            "@${profile.username}",
            style: AppTextStyles.body.copyWith(
              color: customColors.textMuted,
            ),
          ),
        ),

        // ── Bio (Optional) ────────────────────────────────────────────────────
        if (profile.bio != null && profile.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 0),
            child: Text(
              profile.bio!,
              style: AppTextStyles.body.copyWith(
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        const SizedBox(height: 16),

        // ── Stats Row ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              if (uniqueDays > 0)
                Text(
                  "$uniqueDays DAYS LOGGED",
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white70,
                  ),
                ),
              if (!isMe && !isLocked) ...[
                if (uniqueDays > 0) const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    VisibilityResolver.getActivitySignal(null), // TODO: pass actual last log date
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendshipAction(BuildContext ctx, WidgetRef ref) {
    final targetId = profile.id;
    final viewer = currentUser!;
    
    if (viewer.friends.contains(targetId)) {
      return _buildFriendOptions(ctx, ref);
    } else if (viewer.pendingOutgoingRequests.contains(targetId)) {
      return _buildCompactActionBadge(Icons.hourglass_bottom_rounded, 'Sent', Colors.white38);
    } else if (viewer.pendingIncomingRequests.contains(targetId)) {
      return _buildCompactPrimaryAction(
        Icons.person_add_rounded, 
        'Accept', 
        () => _handleAccept(ctx, ref, viewer, profile)
      );
    } else if (viewer.blockedUsers.contains(targetId)) {
      return _buildCompactActionBadge(Icons.block_rounded, 'Blocked', Colors.white24);
    } else {
      return _buildCompactPrimaryAction(
        Icons.person_add_rounded, 
        'Add Friend', 
        () => _handleSendRequest(ctx, ref, viewer, profile)
      );
    }
  }

  Widget _buildFriendOptions(BuildContext ctx, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
      onSelected: (value) => _handleFriendMenu(ctx, ref, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'remove',
          child: Text('Remove Friend'),
        ),
        const PopupMenuItem(
          value: 'block',
          child: Text('Block User', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  void _handleFriendMenu(BuildContext context, WidgetRef ref, String action) {
    if (action == 'remove') {
      ref.read(friendshipRepositoryProvider).removeFriend(currentUser!.id, profile.id).then((_) {
        ref.invalidate(profileDataProvider);
        ref.invalidate(otherProfileDataProvider(profile.id));
      });
    } else if (action == 'block') {
      ref.read(friendshipRepositoryProvider).blockUser(currentUser!.id, profile.id).then((_) {
        ref.invalidate(profileDataProvider);
        ref.invalidate(otherProfileDataProvider(profile.id));
      });
    }
  }

  Future<void> _handleSendRequest(BuildContext context, WidgetRef ref, UserModel currentUser, dynamic targetUser) async {
    try {
      await ref.read(friendshipRepositoryProvider).sendFriendRequest(
        fromUserId: currentUser.id,
        fromUsername: currentUser.displayName,
        fromPhotoUrl: currentUser.photoUrl,
        toUserId: targetUser.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent to ${targetUser.displayName}')),
        );
      }
      ref.invalidate(profileDataProvider);
      ref.invalidate(otherProfileDataProvider(targetUser.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  Future<void> _handleAccept(BuildContext context, WidgetRef ref, UserModel currentUser, dynamic targetUser) async {
    try {
      await ref.read(friendshipRepositoryProvider).acceptFriendRequest(currentUser.id, targetUser.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accepted ${targetUser.displayName}\'s request')),
        );
      }
      ref.invalidate(profileDataProvider);
      ref.invalidate(otherProfileDataProvider(targetUser.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Widget _buildCompactPrimaryAction(IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.amber,
        side: const BorderSide(color: Colors.amber, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildCompactActionBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }


  Future<void> _launchInstagram(BuildContext context, String handle) async {
    final cleanHandle = handle.replaceAll('@', '').trim();
    if (cleanHandle.isEmpty) return;
    
    final url = Uri.parse('https://www.instagram.com/$cleanHandle/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Instagram profile: $e')),
        );
      }
    }
  }
}
