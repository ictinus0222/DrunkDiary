import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/features/drink_logs/models/drink_log_model.dart';
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

  // ---------------------------
  // DIARY LAYOUT
  // ---------------------------
  Widget _diaryLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _photoIfExists(),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _drinkThumbnail(),
            const SizedBox(width: 10),

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

                  _sharedIndicator(),
                ],
              ),
            ),

            const SizedBox(width: 8),
            _timeText(),
          ],
        ),
      ],
    );
  }

  // ---------------------------
  // MEMORY LAYOUT
  // ---------------------------
  Widget _memoryLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _photoIfExists(),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _drinkThumbnail(),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'You rated ${log.alcoholName}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        log.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 16),
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

                  _sharedIndicator(),
                ],
              ),
            ),

            _timeText(),
          ],
        ),
      ],
    );
  }

  // ---------------------------
  // DRINK THUMBNAIL
  // ---------------------------
  Widget _drinkThumbnail() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('alcohols') // 👈 change if needed
          .doc(log.alcoholId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _thumbnailPlaceholder();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _thumbnailFallback();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final imageUrl = data['imageUrl'];

        if (imageUrl == null || imageUrl.isEmpty) {
          return _thumbnailFallback();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbnailFallback(),
          ),
        );
      },
    );
  }


  // ---------------------------
  // SHARED LOG UI
  // ---------------------------
  Widget _sharedIndicator() {
    if (!log.isShared || log.taggedUserIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        Text(
          'with ${log.taggedUserIds.length} people',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 6),

        Row(
          children: log.taggedUserIds.map((uid) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _userAvatar(uid),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _userAvatar(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _fallbackAvatar(userId);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final photoUrl = data['photoUrl'];

        if (photoUrl == null || photoUrl.isEmpty) {
          return _fallbackAvatar(userId);
        }

        return CircleAvatar(
          radius: 14,
          backgroundImage: NetworkImage(photoUrl),
        );
      },
    );
  }

  Widget _fallbackAvatar(String userId) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        userId.substring(0, 1).toUpperCase(),
        style: const TextStyle(fontSize: 12, color: Colors.black),
      ),
    );
  }

  // ---------------------------
  // HELPERS
  // ---------------------------
  Widget _timeText() {
    return Text(
      timeago.format(log.createdAt),
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  Widget _photoIfExists() {
    if (log.photoUrl == null || log.photoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Image.network(
              log.photoUrl!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
  Widget _thumbnailPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.local_bar, color: Colors.grey),
    );
  }

}
