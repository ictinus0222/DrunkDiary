
import 'package:flutter/material.dart';

import '../../drink_logs/models/drink_log_model.dart';

class PublicLogTile extends StatelessWidget {
  final DrinkLogModel log;

  const PublicLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username + Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: log.userPhotoUrl != null
                          ? NetworkImage(log.userPhotoUrl!)
                          : null,
                      child: log.userPhotoUrl == null
                          ? Text(
                        log.username.isNotEmpty
                            ? log.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      )
                          : null,
                    ),


                    const SizedBox(width: 8),

                    Text(
                      log.username,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                Text('⭐ ${log.rating.toStringAsFixed(1)}'),
              ],
            ),


            if (log.note != null && log.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                log.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
