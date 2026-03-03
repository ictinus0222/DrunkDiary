import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../widgets/shelf_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import 'package:drunk_diary/core/navigation/tab_change_notification.dart';

class ShelfScreen extends StatefulWidget {
  static const routeName = '/shelf';
  const ShelfScreen({super.key});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  bool isLoading = true;

  List<AlcoholModel> allShelfAlcohols = [];
  Map<String, int> logCounts = {};
  Map<String, double> avgRatings = {};
  Map<String, DateTime> lastInteraction = {};

  // For Filtering & Sorting
  String searchQuery = '';
  String selectedSort = 'Recent'; // 'Recent', 'Rating', 'Name', 'ABV%'

  // For the glowing shelves
  final List<Color> glowColors = [
    Colors.amber,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.greenAccent,
  ];

  @override
  void initState() {
    super.initState();
    fetchShelfData();
  }

  Future<void> fetchShelfData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentUserId = user.uid;

    final logsSnapshot = await FirebaseFirestore.instance
        .collection('drink_logs')
        .where('userId', isEqualTo: currentUserId)
        .get();

    final Map<String, List<QueryDocumentSnapshot>> groupedLogs = {};

    for (var log in logsSnapshot.docs) {
      final data = log.data();
      final String? alcoholId = data['alcoholId'] as String?;
      if (alcoholId != null) {
        groupedLogs.putIfAbsent(alcoholId, () => []).add(log);
      }
    }

    List<AlcoholModel> alcohols = [];
    Map<String, int> counts = {};
    Map<String, double> ratings = {};
    Map<String, DateTime> interactionMap = {};

    for (var entry in groupedLogs.entries) {
      final alcoholId = entry.key;
      final logs = entry.value;

      final alcoholDoc = await FirebaseFirestore.instance
          .collection('alcohols')
          .doc(alcoholId)
          .get();

      if (!alcoholDoc.exists) continue;

      alcohols.add(AlcoholModel.fromFirestore(alcoholDoc));

      final standardLogs = logs
          .where(
              (l) => (l.data() as Map<String, dynamic>?)?['logKind'] == 'log')
          .toList();
      counts[alcoholId] = standardLogs.length;

      // Calculate Ratings
      final reviewLogs = logs
          .where((l) =>
              (l.data() as Map<String, dynamic>?)?['logKind'] == 'review')
          .toList();

      final ratingsList = reviewLogs
          .map((l) =>
              ((l.data() as Map<String, dynamic>?)?['rating'] as num?)
                  ?.toDouble() ??
              0.0)
          .toList();

      final totalRating =
          ratingsList.isEmpty ? 0.0 : ratingsList.reduce((a, b) => a + b);

      ratings[alcoholId] =
          reviewLogs.isEmpty ? 0.0 : totalRating / reviewLogs.length;

      // Max interaction date
      DateTime maxDate = DateTime.fromMillisecondsSinceEpoch(0);
      for (var l in logs) {
        final data = l.data() as Map<String, dynamic>?;
        if (data != null && data['createdAt'] != null) {
          final ts = data['createdAt'] as Timestamp;
          final d = ts.toDate();
          if (d.isAfter(maxDate)) {
            maxDate = d;
          }
        }
      }
      interactionMap[alcoholId] = maxDate;
    }

    if (mounted) {
      setState(() {
        allShelfAlcohols = alcohols;
        logCounts = counts;
        avgRatings = ratings;
        lastInteraction = interactionMap;
        isLoading = false;
      });
    }
  }

  // --- Sorting Logic ---
  List<AlcoholModel> get filteredAndSortedAlcohols {
    // Filter by search query
    List<AlcoholModel> result = allShelfAlcohols.where((alcohol) {
      if (searchQuery.isNotEmpty) {
        if (!alcohol.name.toLowerCase().contains(searchQuery.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort
    result.sort((a, b) {
      if (selectedSort == 'Rating') {
        return (avgRatings[b.id] ?? 0).compareTo(avgRatings[a.id] ?? 0);
      } else if (selectedSort == 'Name') {
        return a.name.compareTo(b.name);
      } else if (selectedSort == 'ABV%') {
        return b.abv.compareTo(a.abv);
      } else {
        // Recent
        final dateA =
            lastInteraction[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            lastInteraction[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      }
    });

    return result;
  }

  Widget _sortChip(String title) {
    final isSelected = selectedSort == title;
    return GestureDetector(
        onTap: () => setState(() => selectedSort = title),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber : Colors.transparent,
              border: Border.all(
                  color: isSelected ? Colors.amber : Colors.grey.shade600),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(title,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500))));
  }

  @override
  Widget build(BuildContext context) {
    final displayList = filteredAndSortedAlcohols;

    // Chunk list by 3
    List<List<AlcoholModel>> shelves = [];
    for (var i = 0; i < displayList.length; i += 3) {
      shelves.add(displayList.sublist(i, min(i + 3, displayList.length)));
    }

    return Scaffold(
      backgroundColor: Colors.black, // Darkest theme matching design
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text("My Shelf ",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text("${allShelfAlcohols.length} bottles in collection",
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.normal)),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Top Search & Sorts
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: "Search your collection...",
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14)),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    }),
              ),

              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    _sortChip('Recent'),
                    const SizedBox(width: 8),
                    _sortChip('Rating'),
                    const SizedBox(width: 8),
                    _sortChip('Name'),
                    const SizedBox(width: 8),
                    _sortChip('ABV%'),
                  ])),

              const SizedBox(height: 16),

              // Main Shelf View
              Expanded(
                child: shelves.isEmpty
                    ? AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: allShelfAlcohols.isEmpty
                            ? 'Your shelf is empty'
                            : 'No matches found',
                        subtitle: allShelfAlcohols.isEmpty
                            ? 'Log your first drink to start building\nyour personal collection.'
                            : 'Try searching for something else\nor clearing your filters.',
                        buttonText: allShelfAlcohols.isEmpty
                            ? 'Discover Drinks'
                            : 'Clear Search',
                        onAddTap: () {
                          if (allShelfAlcohols.isEmpty) {
                            // Dispatch notification to jump to Search tab
                            const TabChangeNotification(2).dispatch(context);
                          } else {
                            setState(() {
                              searchQuery = '';
                            });
                          }
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 60),
                        itemCount: shelves.length,
                        itemBuilder: (context, index) {
                          final chunk = shelves[index];
                          final Color glow =
                              glowColors[index % glowColors.length];

                          return Column(children: [
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: chunk.map((alcohol) {
                                    return Expanded(
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: ShelfCard(
                                              alcohol: alcohol,
                                              logCount:
                                                  logCounts[alcohol.id] ?? 0,
                                              avgRating:
                                                  avgRatings[alcohol.id] ?? 0,
                                            )));
                                  }).toList()
                                    ..addAll(List.generate(
                                        3 - chunk.length,
                                        (_) =>
                                            const Expanded(child: SizedBox()))),
                                )),
                            const SizedBox(height: 8),

                            // Glowing Shelf Divider
                            Container(
                              height: 8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    // Top faint shelf edge
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.1),
                                      blurRadius: 1,
                                      offset: const Offset(0, -1),
                                    ),
                                    // Bottom strong colorful glow
                                    BoxShadow(
                                      color: glow.withOpacity(0.8),
                                      blurRadius: 10,
                                      offset: const Offset(0,
                                          4), // Shift the glow downwards so it looks like light coming from under the shelf
                                    ),
                                    // A secondary diffuse bottom glow
                                    BoxShadow(
                                      color: glow.withOpacity(0.4),
                                      blurRadius: 25,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                  // Give it a subtle vertical gradient so the top of the shelf looks solid exactly like the screenshot
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.grey.shade600,
                                        Colors.grey.shade900
                                      ])),
                            ),

                            const SizedBox(
                                height: 70), // Spacing to next shelf string
                          ]);
                        },
                      ),
              )
            ]),
    );
  }
}
