import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/alcohol_model.dart';
import '../../models/drink_log_model.dart';

// NOTES:
// This Screen takes an AlcoholModel => Collects a user input => creates a DrinkLogModel => Saves to Firebase

class CreateLogScreen extends StatefulWidget {
  static const String routeName = '/createLog';
  final AlcoholModel alcohol; // Screen is contextual => cannot access without choosing an alcohol.

  const CreateLogScreen({
    super.key,
    required this.alcohol,
  });

  @override
  State<CreateLogScreen> createState() => _CreateLogScreenState();
}

class _CreateLogScreenState extends State<CreateLogScreen> {
  double rating = 0;
  bool hasRated = false; // Edge case handling => prevents accidental zero-star-logs
  String logType = 'memory';
  final TextEditingController reviewController = TextEditingController();

  Future<void> saveLog() async {
    final user = FirebaseAuth.instance.currentUser!;

    // Model Creation:
    final log = DrinkLogModel(
      id: '',
      userId: user.uid,
      alcoholId: widget.alcohol.id,
      alcoholName: widget.alcohol.name,
      alcoholType: widget.alcohol.type,
      rating: rating,
      note: reviewController.text.isNotEmpty
          ? reviewController.text
          : null,
      logType: logType,
      isPublic: false,
      createdAt: DateTime.now(),
      consumedAt: logType == 'diary' ? DateTime.now() : null,
    );

    try {
      await FirebaseFirestore.instance
          .collection('drink_logs')
          .add(log.toMap());

      // Context based SnackBar:
      if (mounted && logType == 'memory') {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged!")),
        );
      } else if (mounted && logType == 'diary') {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added to diary!")),
        );
      } else {
        throw Exception('Invalid log type');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not save log. Please try again."),
          ),
        );
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Log ${widget.alcohol.name}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Rating: ${rating.toStringAsFixed(1)}"),
            Slider(
              value: rating,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (value) {
                setState(() {
                  rating = value;
                  hasRated = true; // if user interacts with slider
                });
              },
            ),

            const SizedBox(height: 12),

            ToggleButtons(
              isSelected: [
                logType == 'memory',
                logType == 'diary',
              ],
              onPressed: (index) {
                setState(() {
                  logType = index == 0 ? 'memory' : 'diary';
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Memory"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Diary"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: reviewController,
              decoration: const InputDecoration(
                labelText: "Review (optional)",
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasRated? saveLog : null,
                child: hasRated ? const Text('Save Log') : const Text('Move the slider to rate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

}
