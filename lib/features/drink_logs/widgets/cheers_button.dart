import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/common_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../activity/providers/activity_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../activity/models/day_activity_model.dart';

class CheersButton extends ConsumerStatefulWidget {
  final String activityId;
  final String activityOwnerId;
  final DateTime activityDate;
  final DayActivityModel? activityData;
  final bool isImmersive;

  const CheersButton({
    super.key,
    required this.activityId,
    required this.activityOwnerId,
    required this.activityDate,
    this.activityData,
    this.isImmersive = false,
  });

  @override
  ConsumerState<CheersButton> createState() => _CheersButtonState();
}

class _CheersButtonState extends ConsumerState<CheersButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  // Local state for optimistic UI
  bool? _isCheeredLocal;
  int? _cheersCountLocal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    final userId = ref.read(userIdProvider);
    final userProfile = ref.read(profileDataProvider).value?.userData;
    if (userId == null) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Trigger animation
    _controller.forward(from: 0.0);

    // Get current state
    final activityData = ref.read(dayActivityProvider(widget.activityId)).value ?? widget.activityData;
    final isCheered = _isCheeredLocal ?? activityData?.cheeredBy.contains(userId) ?? false;
    final currentCount = _cheersCountLocal ?? activityData?.cheersCount ?? 0;

    // Optimistic update
    setState(() {
      _isCheeredLocal = !isCheered;
      _cheersCountLocal = !isCheered ? currentCount + 1 : currentCount - 1;
    });

    try {
      await ref.read(dayActivityRepositoryProvider).toggleCheers(
        activityId: widget.activityId,
        userId: userId,
        date: widget.activityDate,
        activityOwnerId: widget.activityOwnerId,
        senderUsername: userProfile?.username,
        senderProfileImage: userProfile?.photoUrl,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        _isCheeredLocal = isCheered;
        _cheersCountLocal = currentCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update Cheers')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final activityAsync = ref.watch(dayActivityProvider(widget.activityId));
    final activityData = activityAsync.value ?? widget.activityData;
    
    // Sync local state if data from stream changed
    final isCheered = _isCheeredLocal ?? activityData?.cheeredBy.contains(userId) ?? false;
    final cheersCount = _cheersCountLocal ?? activityData?.cheersCount ?? 0;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: widget.isImmersive 
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(vertical: 4),
        decoration: widget.isImmersive 
            ? BoxDecoration(
                color: isCheered ? Colors.amber.withOpacity(0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCheered ? Colors.amber.withOpacity(0.5) : Colors.white24,
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Opacity(
                opacity: isCheered ? 1.0 : (widget.isImmersive ? 0.8 : 0.4),
                child: const Text(
                  '🥂',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$cheersCount ${cheersCount == 1 ? 'Cheers' : 'Cheers'}',
              style: GoogleFonts.dmSans(
                color: isCheered ? Colors.amber : (widget.isImmersive ? Colors.white : Colors.white.withValues(alpha: 0.5)),
                fontWeight: isCheered ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
