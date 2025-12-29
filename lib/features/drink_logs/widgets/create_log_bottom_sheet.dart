import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../models/drink_log_model.dart';

class CreateLogBottomSheet extends StatefulWidget {
  final AlcoholModel alcohol;
  const CreateLogBottomSheet({super.key, required this.alcohol});

  @override
  State<CreateLogBottomSheet> createState() => _CreateLogBottomSheetState();
}

class _CreateLogBottomSheetState extends State<CreateLogBottomSheet> {
  double rating = 0;
  bool hasRated = false;
  String logType = 'memory';
  final TextEditingController reviewController = TextEditingController();
  bool isSaving = false;

  Future<void> saveLog() async {
    if (isSaving) return;

    final user = FirebaseAuth.instance.currentUser!;
    setState(() => isSaving = true);

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

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not save log. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16,),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log ${widget.alcohol.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          Text('Rating: ${rating.toStringAsFixed(1)}'),
          Slider(
            value: rating,
            min: 0,
            max: 5,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                rating = value;
                hasRated = true;
              });
            },
          ),

          const SizedBox(height: 8),

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
                child: Text('Memory'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Diary'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextField(
            controller: reviewController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasRated && !isSaving ? saveLog : null,
              child: isSaving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(
                hasRated
                    ? 'Save Log'
                    : 'Move the slider to rate',
              ),
            ),

          ),
        ],
      ),
    );
  }
}
