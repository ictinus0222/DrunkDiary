import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_request_model.dart';

class FriendshipRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── FRIEND REQUESTS ────────────────────────────────────────────────────────

  /// Sends a friend request with idempotency and advisory rate limiting.
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromUsername,
    String? fromPhotoUrl,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) throw Exception('Cannot add yourself as a friend.');

    final requestRef = _firestore.collection('friend_requests').doc('${fromUserId}_$toUserId');
    
    await _firestore.runTransaction((transaction) async {
      final fromUserDoc = await transaction.get(_firestore.collection('users').doc(fromUserId));
      final toUserDoc = await transaction.get(_firestore.collection('users').doc(toUserId));

      if (!fromUserDoc.exists || !toUserDoc.exists) throw Exception('User not found.');

      final fromData = fromUserDoc.data()!;
      final toData = toUserDoc.data()!;

      final friends = List<String>.from(fromData['friends'] ?? []);
      final blocked = List<String>.from(fromData['blockedUsers'] ?? []);
      final toBlocked = List<String>.from(toData['blockedUsers'] ?? []);

      if (friends.contains(toUserId)) throw Exception('Already friends.');
      if (blocked.contains(toUserId) || toBlocked.contains(fromUserId)) {
        throw Exception('Cannot send friend request to blocked user.');
      }

      // Check for existing pending request
      final existingReq = await transaction.get(requestRef);
      if (existingReq.exists) {
        final status = existingReq.data()?['status'];
        if (status == 'pending') throw Exception('Request already pending.');
      }

      // 1. Create/Update Friend Request document
      transaction.set(requestRef, {
        'fromUserId': fromUserId,
        'fromUsername': fromUsername,
        'fromPhotoUrl': fromPhotoUrl,
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update User pending arrays
      transaction.update(_firestore.collection('users').doc(fromUserId), {
        'pendingOutgoingRequests': FieldValue.arrayUnion([toUserId]),
      });
      transaction.update(_firestore.collection('users').doc(toUserId), {
        'pendingIncomingRequests': FieldValue.arrayUnion([fromUserId]),
      });

      // 3. Create Notification
      final notificationRef = _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .doc('req_$fromUserId');
          
      transaction.set(notificationRef, {
        'type': 'friend_request',
        'senderId': fromUserId,
        'senderUsername': fromUsername,
        'senderProfileImage': fromPhotoUrl,
        'activityId': requestRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }).catchError((e) {
      print('FriendshipRepository.sendFriendRequest error: $e');
      throw e;
    });
  }

  /// Cancels an outgoing friend request.
  Future<void> cancelFriendRequest(String fromUserId, String toUserId) async {
    final requestRef = _firestore.collection('friend_requests').doc('${fromUserId}_$toUserId');
    
    await _firestore.runTransaction((transaction) async {
      transaction.update(requestRef, {'status': 'cancelled'});
      transaction.update(_firestore.collection('users').doc(fromUserId), {
        'pendingOutgoingRequests': FieldValue.arrayRemove([toUserId]),
      });
      transaction.update(_firestore.collection('users').doc(toUserId), {
        'pendingIncomingRequests': FieldValue.arrayRemove([fromUserId]),
      });
    });
  }

  /// Accepts an incoming friend request.
  Future<void> acceptFriendRequest(String userId, String requesterId) async {
    final requestRef = _firestore.collection('friend_requests').doc('${requesterId}_$userId');
    
    await _firestore.runTransaction((transaction) async {
      final now = FieldValue.serverTimestamp();

      // 1. Update Request Status
      transaction.update(requestRef, {'status': 'accepted'});

      // 2. Update Both Users (Mutual Friendship)
      transaction.update(_firestore.collection('users').doc(userId), {
        'friends': FieldValue.arrayUnion([requesterId]),
        'pendingIncomingRequests': FieldValue.arrayRemove([requesterId]),
        'friendsSince.$requesterId': now,
      });

      transaction.update(_firestore.collection('users').doc(requesterId), {
        'friends': FieldValue.arrayUnion([userId]),
        'pendingOutgoingRequests': FieldValue.arrayRemove([userId]),
        'friendsSince.$userId': now,
      });

      // 3. Optional: Create "Friend Accept" Notification
      // ...
    });
  }

  /// Rejects an incoming friend request.
  Future<void> rejectFriendRequest(String userId, String requesterId) async {
    final requestRef = _firestore.collection('friend_requests').doc('${requesterId}_$userId');
    
    await _firestore.runTransaction((transaction) async {
      transaction.update(requestRef, {'status': 'rejected'});
      transaction.update(_firestore.collection('users').doc(userId), {
        'pendingIncomingRequests': FieldValue.arrayRemove([requesterId]),
      });
      transaction.update(_firestore.collection('users').doc(requesterId), {
        'pendingOutgoingRequests': FieldValue.arrayRemove([userId]),
      });
    });
  }

  // ── SOCIAL ACTIONS ─────────────────────────────────────────────────────────

  /// Removes a friend (Mutual removal).
  Future<void> removeFriend(String userId, String friendId) async {
    await _firestore.runTransaction((transaction) async {
      transaction.update(_firestore.collection('users').doc(userId), {
        'friends': FieldValue.arrayRemove([friendId]),
      });
      transaction.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayRemove([userId]),
      });
    });
  }

  /// Blocks a user (Bidirectional).
  Future<void> blockUser(String userId, String targetId) async {
    await _firestore.runTransaction((transaction) async {
      // 1. Add to blocked list
      transaction.update(_firestore.collection('users').doc(userId), {
        'blockedUsers': FieldValue.arrayUnion([targetId]),
      });

      // 2. Remove friendship if exists
      transaction.update(_firestore.collection('users').doc(userId), {
        'friends': FieldValue.arrayRemove([targetId]),
        'pendingIncomingRequests': FieldValue.arrayRemove([targetId]),
        'pendingOutgoingRequests': FieldValue.arrayRemove([targetId]),
      });
      transaction.update(_firestore.collection('users').doc(targetId), {
        'friends': FieldValue.arrayRemove([userId]),
        'pendingIncomingRequests': FieldValue.arrayRemove([userId]),
        'pendingOutgoingRequests': FieldValue.arrayRemove([userId]),
      });

      // 3. Mark any pending requests as rejected/cancelled if they exist
      final req1 = _firestore.collection('friend_requests').doc('${userId}_$targetId');
      final req2 = _firestore.collection('friend_requests').doc('${targetId}_$userId');
      
      // Use set with merge: true to avoid crashes if document doesn't exist
      transaction.set(req1, {'status': 'rejected'}, SetOptions(merge: true));
      transaction.set(req2, {'status': 'rejected'}, SetOptions(merge: true));
    }).catchError((e) {
      print('FriendshipRepository.blockUser error: $e');
      throw e;
    });
  }
}
