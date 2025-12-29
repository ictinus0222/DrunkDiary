import 'package:flutter/material.dart';

import '../../profile/models/profile_data.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../profile/widgets/profile_content.dart';

class PublicProfileScreen extends StatelessWidget {
  final String username;

  const PublicProfileScreen({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final repository = ProfileRepository();

    return Scaffold(
      appBar: AppBar(
        title: Text('@$username'),
      ),
      body: FutureBuilder<ProfileData?>(
        future: repository.fetchPublicProfileByUsername(username),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔒 Private or non-existent profile
          if (!snapshot.hasData || snapshot.data == null) {
            return const _PrivateProfileState();
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            child: ProfileContent(
              user: profile.user,
              stats: profile.stats,
            ),
          );
        },
      ),
    );
  }
}

/// Simple, calm empty state for MVP
class _PrivateProfileState extends StatelessWidget {
  const _PrivateProfileState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'This profile is private or does not exist',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
