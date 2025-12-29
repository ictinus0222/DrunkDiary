import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/drink_log_model.dart';

class LogDetailBottomSheet extends StatelessWidget {
  final DrinkLogModel log;

  const LogDetailBottomSheet({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: _buildContentByLogType(),
    );
  }

  Widget _buildContentByLogType() {
    switch (log.logType) {
      case 'memory':
        return _memoryDetail();
      case 'diary':
      default:
        return _diaryDetail();
    }
  }

  Widget _diaryDetail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
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

        if (log.note != null && log.note!.isNotEmpty)
          Text(
            log.note!,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),

        const SizedBox(height: 24),

        _timestamp(),
      ],
    );
  }

  Widget _memoryDetail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
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

        if (log.note != null && log.note!.isNotEmpty)
          Text(
            log.note!,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),

        const SizedBox(height: 24),

        _timestamp(),
      ],
    );
  }

  Widget _timestamp() {
    final formatter = DateFormat('dd MMM yyyy • hh:mm a');

    return Text(
      'Logged on ${formatter.format(log.createdAt)}',
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    );
  }
}
