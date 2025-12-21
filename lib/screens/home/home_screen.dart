import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/alcohol_model.dart';
import '../alcohol/alcohol_detail_screen.dart';

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
                final alcohol = await _fetchOneAlcohol();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlcoholDetailScreen(
                        alcoholId: alcohol.id,
                        initialAlcohol: alcohol),
                  ),
                );
              },
              child: const Text("Go to Alcohol Detail"),
            )
          ],

        ),

      ),
    );
  }

  Future<AlcoholModel> _fetchOneAlcohol() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('alcohols')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('No alcohols found');
    }

    return AlcoholModel.fromFirestore(snapshot.docs.first);
  }

}
