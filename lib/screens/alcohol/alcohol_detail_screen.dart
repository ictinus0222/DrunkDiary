import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/alcohol_model.dart';
import '../drink_logs/create_log_screen.dart';

class AlcoholDetailScreen extends StatelessWidget {
  static const routeName = '/alcoholDetail';

  final String alcoholId;
  final AlcoholModel? initialAlcohol;

  const AlcoholDetailScreen({
    super.key,
    required this.alcoholId,
    this.initialAlcohol,
  });
  Future<AlcoholModel> _fetchAlcohol() async {
    final doc = await FirebaseFirestore.instance
        .collection('alcohols')
        .doc(alcoholId)
        .get();

    return AlcoholModel.fromFirestore(doc);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AlcoholModel>(
      future: initialAlcohol != null
        ? Future.value(initialAlcohol)
        : _fetchAlcohol(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState ==ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Alcohol not found / error state
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Alcohol not found')),
          );
        }
        final alcohol = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(alcohol.name),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alcohol.brand,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text("${alcohol.type} • ${alcohol.abv}% ABV"),
                const SizedBox(height: 16),
                Text(alcohol.description),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateLogScreen(alcohol: alcohol),
                        ),
                      );
                    },
                    child: const Text("Log this drink"),
                  ),

                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
