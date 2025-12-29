import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/drink_log_model.dart';

class LogDetailBottomSheet extends StatefulWidget {
  final DrinkLogModel log;

  const LogDetailBottomSheet({
    super.key,
    required this.log,
  });

  @override
  State<LogDetailBottomSheet> createState() =>
      _LogDetailBottomSheetState();
}

class _LogDetailBottomSheetState extends State<LogDetailBottomSheet> {
  late String visibility;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    visibility = widget.log.visibility;
  }

  Future<void> _updateVisibility(String value) async {
    if (value == visibility) return;

    setState(() {
      visibility = value;
      isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('drink_logs')
          .doc(widget.log.id)
          .update({
        'visibility': value,
      });
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

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
    switch (widget.log.logType) {
      case 'memory':
        return _memoryDetail();
      case 'diary':
      default:
        return _diaryDetail();
    }
  }

  // =======================
  // DIARY LOG DETAIL
  // =======================
  Widget _diaryDetail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.log.alcoholName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          widget.log.alcoholType,
          style: const TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            const Icon(Icons.star, size: 22),
            const SizedBox(width: 6),
            Text(
              widget.log.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (widget.log.note != null && widget.log.note!.isNotEmpty)
          Text(
            widget.log.note!,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),

        const SizedBox(height: 24),

        _visibilityToggle(),

        const SizedBox(height: 24),

        _timestamp(),
      ],
    );
  }

  // =======================
  // MEMORY LOG DETAIL
  // =======================
  Widget _memoryDetail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You rated ${widget.log.alcoholName}',
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
              widget.log.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (widget.log.note != null && widget.log.note!.isNotEmpty)
          Text(
            widget.log.note!,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),

        const SizedBox(height: 24),

        _visibilityToggle(),

        const SizedBox(height: 24),

        _timestamp(),
      ],
    );
  }

  // =======================
  // VISIBILITY TOGGLE
  // =======================
  Widget _visibilityToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visibility',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            ChoiceChip(
              label: const Text('Public'),
              selected: visibility == 'public',
              onSelected: isUpdating
                  ? null
                  : (_) => _updateVisibility('public'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Private'),
              selected: visibility == 'private',
              onSelected: isUpdating
                  ? null
                  : (_) => _updateVisibility('private'),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          visibility == 'public'
              ? 'This log is visible to others on this drink.'
              : 'Only you can see this log.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // =======================
  // TIMESTAMP
  // =======================
  Widget _timestamp() {
    final formatter = DateFormat('dd MMM yyyy • hh:mm a');

    return Text(
      'Logged on ${formatter.format(widget.log.createdAt)}',
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
      ),
    );
  }
}
