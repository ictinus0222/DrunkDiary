import '../../features/profile/models/user_model.dart';
import '../../features/drink_logs/models/drink_model_dto.dart';

class VisibilityResolver {
  /// The central permission engine for DrunkDiary.
  /// Rule Priority: 
  /// 1. Self (Always allowed)
  /// 2. Blocked (Bidirectional cutoff)
  /// 3. Post Visibility (Public > FriendsOnly > CloseFriends)
  
  static bool canViewProfile({
    required UserModel viewer,
    required UserModel owner,
  }) {
    // 1. Self Override
    if (viewer.id == owner.id) return true;

    // 2. Bidirectional Block
    if (owner.blockedUsers.contains(viewer.id) || 
        viewer.blockedUsers.contains(owner.id)) {
      return false;
    }

    // For profile itself, if it's not private, anyone can see it.
    // If it's private, only friends can see full activity.
    // metadata is handled separately in UI (discovery).
    return !owner.isPrivate || 
           owner.friends.contains(viewer.id) || 
           viewer.friends.contains(owner.id);
  }

  static bool canViewLog({
    required UserModel viewer,
    required UserModel owner,
    required Visibility visibility,
  }) {
    // 1. Self Override
    if (viewer.id == owner.id) return true;

    // 2. Bidirectional Block
    if (owner.blockedUsers.contains(viewer.id) || 
        viewer.blockedUsers.contains(owner.id)) {
      return false;
    }

    // 3. Post Visibility
    switch (visibility) {
      case Visibility.public:
        return true;
      case Visibility.friendsOnly:
        return owner.friends.contains(viewer.id) || viewer.friends.contains(owner.id);
      case Visibility.closeFriends:
        // For MVP, closeFriends behaves like friendsOnly or is restricted further
        // TODO: Implement closeFriends array check
        return owner.friends.contains(viewer.id) || viewer.friends.contains(owner.id);
    }
  }

  static bool canViewFeedItem({
    required UserModel viewer,
    required UserModel owner,
    required Visibility visibility,
  }) {
    // Shared logic with canViewLog for now
    return canViewLog(viewer: viewer, owner: owner, visibility: visibility);
  }

  /// Derives safe activity signals without leaking exact timestamps.
  static String getActivitySignal(DateTime? lastLogDate) {
    if (lastLogDate == null) return 'No activity yet';
    
    final now = DateTime.now();
    final difference = now.difference(lastLogDate);

    if (difference.inDays < 7) {
      return 'Recently Active';
    } else if (difference.inDays < 30) {
      return 'Active This Month';
    } else {
      return 'Quiet Recently';
    }
  }
}
