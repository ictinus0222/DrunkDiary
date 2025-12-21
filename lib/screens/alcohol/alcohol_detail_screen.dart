import 'package:flutter/material.dart';
import '../../models/alcohol_model.dart';
import '../drink_logs/create_log_screen.dart';

class AlcoholDetailScreen extends StatelessWidget {
  static const routeName = '/alcoholDetail';
  final AlcoholModel alcohol;

  const AlcoholDetailScreen({
    super.key,
    required this.alcohol,
  });

  @override
  Widget build(BuildContext context) {
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
}
