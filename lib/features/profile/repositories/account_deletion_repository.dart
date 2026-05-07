import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountDeletionRepositoryProvider = Provider((ref) => AccountDeletionRepository());

class AccountDeletionRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userId = user.uid;

    try {
      // 1. Delete Firestore Data
      await _deleteFirestoreData(userId);

      // 2. Delete Storage Files
      await _deleteStorageFiles(userId);

      // 3. Delete Auth Account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'reauthentication-required';
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _deleteFirestoreData(String userId) async {
    final batch = _firestore.batch();

    // 1. Delete user document
    batch.delete(_firestore.collection('users').doc(userId));

    // 2. Delete logs (with pagination/loop to handle large amounts)
    await _deleteCollectionByQuery(
      _firestore.collection('drink_logs').where('userId', isEqualTo: userId),
    );

    // 3. Delete activity sessions
    await _deleteCollectionByQuery(
      _firestore.collection('activity_sessions').where('userId', isEqualTo: userId),
    );

    // 4. Delete wishlist items
    await _deleteCollectionByQuery(
      _firestore.collection('wishlists').where('userId', isEqualTo: userId),
    );

    // 5. Delete notifications (subcollection)
    await _deleteCollectionByPath('users/$userId/notifications');

    // Commit the main user doc deletion
    await batch.commit();
  }

  Future<void> _deleteCollectionByQuery(Query query) async {
    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return;

    // Firestore batch limit is 500
    final chunks = _chunkList(snapshot.docs, 500);
    
    for (var chunk in chunks) {
      final batch = _firestore.batch();
      for (var doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteCollectionByPath(String path) async {
    final snapshot = await _firestore.collection(path).get();
    if (snapshot.docs.isEmpty) return;

    final chunks = _chunkList(snapshot.docs, 500);
    
    for (var chunk in chunks) {
      final batch = _firestore.batch();
      for (var doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteStorageFiles(String userId) async {
    final folders = ['drink_logs', 'profiles'];
    
    for (final folder in folders) {
      try {
        final folderRef = _storage.ref().child(folder).child(userId);
        final listResult = await folderRef.listAll();
        
        for (var item in listResult.items) {
          await item.delete();
        }
      } catch (e) {
        // If folder doesn't exist or other error, just continue
        print('Error deleting storage files in $folder: $e');
      }
    }
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }
}
