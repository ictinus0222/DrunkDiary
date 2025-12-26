import 'package:drunk_diary/models/drink_log_model.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'log_detail_bottom_sheet.dart';

class DrinkLogCard extends StatelessWidget {
  final DrinkLogModel log;

  const DrinkLogCard({super.key, required this.log});

  String get relativeTime {
    return timeago.format(log.createdAt, locale: 'en');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => LogDetailBottomSheet(log: log),
        );

      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _buildContentByLogType(),
        ),
      ),
    );
  }

  Widget _buildContentByLogType() {
    switch (log.logType) {
      case 'memory':
        return _memoryLayout();
      case 'diary':
      default:
        return _diaryLayout();
    }
  }
  Widget _diaryLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.local_bar, size: 20),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You drank ${log.alcoholName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Text(log.rating.toStringAsFixed(1)),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 14),
                ],
              ),

              if (log.note != null && log.note!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  log.note!,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),

        Column(
          children: [
            _timeText(),
            ],
        ),
      ],


    );
  }
  Widget _memoryLayout() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'You rated ${log.alcoholName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      log.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 16),


                  ],
                ),


              ],
            ),

            if (log.note != null && log.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                log.note!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),

        const Spacer(),


        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _timeText(),
          ],
        ),
      ],
    );
  }

  Widget _timeText() {
    return Text(
      timeago.format(log.createdAt),
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }


}
