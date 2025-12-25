import 'package:drunk_diary/models/drink_log_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LogDetailScreen extends StatelessWidget {
  static const routeName = '/logDetail';

  final DrinkLogModel log;

  const LogDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContentByLogType(),
      ),
    );
  }

  Widget _buildContentByLogType() {
  switch (log.logType) {
    case 'memory':
      return _memoryDetail();
    case 'diary':
    default: return _diaryDetail();
  }
  }

  Widget _diaryDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.alcoholName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            log.alcoholType,
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.star, size: 22),
              const SizedBox(width: 6),
              Text(
                log.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
              ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (log.note !=null && log.note!.isNotEmpty)
            Text(
              log.note!,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),

          const Spacer(),

          _timestamps(),
        ],
    );
  }
  Widget _memoryDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You rated ${log.alcoholName}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            const Icon(Icons.star, size: 24),
            const SizedBox(width: 6),
            Text(
              log.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (log.note !=null && log.note!.isNotEmpty)
          Text(
            log.note!,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),

        const Spacer(),

        _timestamps(),
      ],
    );
  }

  Widget _timestamps() {
    final formatter = DateFormat('dd MMM yyyy • hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logged on ${formatter.format(log.createdAt)}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }


}
