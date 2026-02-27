import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/drink_model_dto.dart';

class LogDetailBottomSheet extends StatefulWidget {
  final DrinkLogModel log;

  const LogDetailBottomSheet({
    super.key,
    required this.log,
  });

  @override
  State<LogDetailBottomSheet> createState() => _LogDetailBottomSheetState();
}

class _LogDetailBottomSheetState extends State<LogDetailBottomSheet> {
  bool isDeleting = false;

  // =======================
  // DELETE LOG
  // =======================
  Future<void> _deleteLog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete log?'),
        content: const Text(
          'This action can’t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isDeleting = true);

    await FirebaseFirestore.instance
        .collection('drink_logs')
        .doc(widget.log.id)
        .delete();

    if (mounted) Navigator.pop(context);
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
      child: _buildContentByLogKind(),
    );
  }

  // =======================
  // CONTENT SWITCH
  // =======================
  Widget _buildContentByLogKind() {
    switch (widget.log.logKind) {
      case LogKind.review:
        return _reviewDetail();

      case LogKind.log:
      default:
        return _logDetail();
    }
  }

  // =======================
  // LOG DETAIL (PRIVATE)
  // =======================
  Widget _logDetail() {
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
            Icon(
              widget.log.isLiked == true ? Icons.thumb_up : Icons.thumb_down,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              widget.log.isLiked == true ? 'Liked' : 'Didn’t like',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
        _timestamp(),
        const SizedBox(height: 16),
        _deleteAction(),
      ],
    );
  }

  // =======================
  // REVIEW DETAIL (PUBLIC)
  // =======================
  Widget _reviewDetail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review of ${widget.log.alcoholName}',
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
              (widget.log.rating ?? 0.0).toStringAsFixed(1),
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
            ),
          ),
        const SizedBox(height: 24),
        const Text(
          'This review is public.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        _timestamp(),
        const SizedBox(height: 16),
        _deleteAction(),
      ],
    );
  }

  // =======================
  // DELETE ACTION
  // =======================
  Widget _deleteAction() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.delete, color: Colors.red),
      title: const Text(
        'Delete',
        style: TextStyle(color: Colors.red),
      ),
      onTap: isDeleting ? null : _deleteLog,
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
