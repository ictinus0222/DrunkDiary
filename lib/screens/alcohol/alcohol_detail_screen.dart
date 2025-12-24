import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/alcohol_model.dart';
import '../../widgets/alcohol_activity_widget.dart';
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🍾 Alcohol Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.network(
                      alcohol.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.local_bar, size: 64),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🏷️ Alcohol Identity
                Text(
                  alcohol.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),

                Text(
                  "${alcohol.brand} • ${alcohol.origin}",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: alcohol.type),
                    _InfoChip(label: "${alcohol.abv}% ABV"),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  "About this drink",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),

                if (alcohol.description.isNotEmpty)
                  Text(
                    alcohol.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),


                // 🧠 Activity
                const SizedBox(height: 32),

                Text(
                  "Your activity",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),

                AlcoholActivityWidget(
                  alcoholId: alcohol.id,
                ),

              ],
            ),
          ),

          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Log this drink"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateLogScreen(alcohol: alcohol),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.black),
      ),
    );
  }
}

