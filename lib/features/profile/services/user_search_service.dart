import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserSearchResult>> searchUsers(String query) async {
    final lowercaseQuery = query.toLowerCase().trim();
    print('Searching users for: $lowercaseQuery');
    
    // Debug test case
    if (lowercaseQuery == 'debug') {
      return [
        UserSearchResult(
          user: UserModel(
            id: 'debug-id',
            username: 'debug_user',
            usernameLowercase: 'debug_user',
            displayName: 'Debug User',
            displayNameLowercase: 'debug user',
            isPrivate: false,
            ageVerified: true,
            createdAt: DateTime.now(),
          ),
          score: 100,
        ),
      ];
    }

    if (lowercaseQuery.length < 2) return [];

    try {
      // 1. Search by Username Lowercase (Optimized)
      final usernameQuery = await _firestore
          .collection('users')
          .where('usernameLowercase', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('usernameLowercase', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
          .limit(20)
          .get();

      // 2. Search by Display Name Lowercase (Optimized)
      final displayNameQuery = await _firestore
          .collection('users')
          .where('displayNameLowercase', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('displayNameLowercase', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
          .limit(20)
          .get();

      // 3. LEGACY FALLBACK: Search by username prefix (case-sensitive)
      // This helps find users as you type, even if they haven't updated their profile yet.
      final legacyUsernameQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.trim())
          .where('username', isLessThanOrEqualTo: '${query.trim()}\uf8ff')
          .limit(10)
          .get();

      print('Query results: usernameLowercase=${usernameQuery.docs.length}, displayNameLowercase=${displayNameQuery.docs.length}, legacy=${legacyUsernameQuery.docs.length}');

      final Map<String, UserSearchResult> results = {};

      void processDocs(QuerySnapshot snapshot, bool isUsernameMatch) {
        for (var doc in snapshot.docs) {
          final user = UserModel.fromFirestore(doc);
          final score = _calculateScore(user.usernameLowercase, user.displayNameLowercase, lowercaseQuery, isUsernameMatch);
          
          if (results.containsKey(user.id)) {
            if (score > results[user.id]!.score) {
              results[user.id] = UserSearchResult(user: user, score: score);
            }
          } else {
            results[user.id] = UserSearchResult(user: user, score: score);
          }
        }
      }

      processDocs(usernameQuery, true);
      processDocs(displayNameQuery, false);
      processDocs(legacyUsernameQuery, true);

      final sortedResults = results.values.toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      return sortedResults.take(20).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  int _calculateScore(String username, String displayName, String query, bool isUsernameMatch) {
    // Scoring system:
    // Exact Username: 100
    // Exact Display Name: 90
    // Username startsWith: 70
    // Display Name startsWith: 60
    // Partial Match: 30

    if (username == query) return 100;
    if (displayName == query) return 90;
    
    if (username.startsWith(query)) return 70;
    if (displayName.startsWith(query)) return 60;
    
    return 30; // Partial match (Firestore query already handles contains-like behavior for startsWith)
  }
}

class UserSearchResult {
  final UserModel user;
  final int score;

  UserSearchResult({required this.user, required this.score});
}
