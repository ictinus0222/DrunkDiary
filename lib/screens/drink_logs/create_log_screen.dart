import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/alcohol_model.dart';
import '../../models/drink_log_model.dart';

class CreateLogScreen extends StatefulWidget {
  static const String routeName = '/createLog';
  final AlcoholModel alcohol;

  const CreateLogScreen({
    super.key,
    required this.alcohol,
  });

  @override
  State<CreateLogScreen> createState() => _CreateLogScreenState();
}

class _CreateLogScreenState extends State<CreateLogScreen> {
  double rating = 3;
  String logType = 'retro';
  final TextEditingController reviewController = TextEditingController();

  Future<void> saveLog() async {
    final user = FirebaseAuth.instance.currentUser!;

    final log = DrinkLogModel(
      id: '',
      userId: user.uid,
      alcoholId: widget.alcohol.id,
      alcoholName: widget.alcohol.name,
      alcoholType: widget.alcohol.type,
      rating: rating,
      review: reviewController.text.isNotEmpty
          ? reviewController.text
          : null,
      logType: logType,
      visibility: 'private',
      loggedAt: DateTime.now(),
      drankAt: logType == 'diary' ? DateTime.now() : null,
    );

    await FirebaseFirestore.instance
        .collection('drink_logs')
        .add(log.toMap());

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to your Shelf 🍻")),
      );
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
                setState(() => rating = value);
              },
            ),

            const SizedBox(height: 12),

            ToggleButtons(
              isSelected: [
                logType == 'retro',
                logType == 'diary',
              ],
              onPressed: (index) {
                setState(() {
                  logType = index == 0 ? 'retro' : 'diary';
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Retro"),
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
                onPressed: saveLog,
                child: const Text("Save Log"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
