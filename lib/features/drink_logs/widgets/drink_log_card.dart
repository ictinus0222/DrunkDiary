import 'package:flutter/material.dart';

import '../models/drink_model_dto.dart';
import 'log_detail_bottom_sheet.dart';

class DrinkLogCard extends StatelessWidget {
  final DrinkLogModel log;

  const DrinkLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: log.logKind == LogKind.review
              ? Colors.grey.shade900
              : const Color(0xFF121212),
          border: Border.all(
            color: log.logKind == LogKind.review
                ? Colors.amber.withOpacity(0.3)
                : Colors.grey.shade800,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerImage(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleRow(),
                  const SizedBox(height: 6),
                  _metaRow(),
                  const SizedBox(height: 14),
                  _caption(),
                  const SizedBox(height: 14),
                  _chipsRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // HEADER IMAGE
  // ----------------------------
  Widget _headerImage() {
    if (log.photoUrl == null || log.photoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          log.photoUrl!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ----------------------------
  // TITLE + RATING
  // ----------------------------
  Widget _titleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            log.alcoholName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        if (log.logKind == LogKind.review)
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < (log.rating?.round() ?? 0)
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 16,
              ),
            ),
          )
        else
          Icon(
            log.isLiked == true ? Icons.thumb_up : Icons.thumb_down,
            color: log.isLiked == true ? Colors.green : Colors.red,
            size: 20,
          ),
      ],
    );
  }

  // ----------------------------
  // DATE + VISIBILITY
  // ----------------------------
  Widget _metaRow() {
    return Text(
      _formattedDate(),
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade400,
      ),
    );
  }

  String _formattedDate() {
    return '${log.createdAt.day} '
        '${_monthName(log.createdAt.month)}, '
        '${log.createdAt.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // ----------------------------
  // CAPTION
  // ----------------------------
  Widget _caption() {
    if (log.note == null || log.note!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      log.note!,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade300,
      ),
    );
  }

  // ----------------------------
  // INFO CHIPS (model-safe)
  // ----------------------------
  Widget _chipsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(log.alcoholType),
        _chip(log.logKind == LogKind.review ? 'Review' : 'Log'),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
