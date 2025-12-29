import 'package:drunk_diary/features/drink_logs/screens/shelf_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../alcohol/screens/alcohol_search_screen.dart';
import '../../drink_logs/screens/diary_timeline_screen.dart';
import '../../activity/screens/user_activity_screen.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DrunkDiary 🍻'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You are signed in 🎉',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (user != null) ...[
              Text(
                user.displayName ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 30),
            const Text(
              'This is your Home Screen.\nBuild chaos responsibly 🍻',
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () async {
                // final alcohol = await _fetchOneAlcohol();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlcoholSearchScreen(),
                  ),
                );
              },
              child: const Text("Search Alcohols"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DiaryTimelineScreen(),
                  ),
                );
              },
              child: const Text("Go to Diary 📖"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActivityScreen(),
                  ),
                );
              },
              child: const Text("Go to Activity ⏳"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShelfScreen(),
                  ),
                );
              },
              child: const Text("Go to Shelf 🍻"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              child: const Text("Go to Profile 👤"),
            ),

          ],

        ),

      ),
    );
  }

}
