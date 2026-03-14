import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/app_theme.dart';
import '../../alcohol/repositories/alcohol_repository.dart';
import '../../drink_logs/models/drink_model_dto.dart';
import '../models/discover_item_model.dart';
import '../widgets/discover_alcohol_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../../core/widgets/app_empty_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _alcoholRepo = AlcoholRepository();

  bool _isLoading = true;
  String _error = '';

  List<DiscoverItemModel> _allAlcohols = [];
  List<DiscoverItemModel> _filteredAlcohols = [];
  List<String> _availableTypes = [];

  // Filter & Sort State
  String _searchQuery = '';
  DiscoverSortOption _selectedSort = DiscoverSortOption.random;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // 1. Fetch Alcohols
      final alcohols = await _alcoholRepo.getAllAlcohols();

      // 2. Fetch Logs
      final logsSnapshot =
          await FirebaseFirestore.instance.collection('drink_logs').get();
      final logs = logsSnapshot.docs.map(DrinkLogModel.fromFirestore).toList();

      // 3. Process Data
      final Set<String> typesList = {};
      final List<DiscoverItemModel> items = [];

      for (var alcohol in alcohols) {
        typesList.add(alcohol.type);

        final alcoholLogs =
            logs.where((l) => l.alcoholId == alcohol.id).toList();
        final reviews =
            alcoholLogs.where((l) => l.logKind == LogKind.review).toList();

        double avg = 0.0;
        if (reviews.isNotEmpty) {
          final ratings = reviews.map((r) => r.rating ?? 0.0).toList();
          avg = ratings.reduce((a, b) => a + b) / ratings.length;
        }

        final userLogs =
            alcoholLogs.where((l) => l.userId == user.uid).toList();
        final hasLogged = userLogs.any((l) => l.logKind == LogKind.log);
        final hasReviewed = userLogs.any((l) => l.logKind == LogKind.review);

        items.add(DiscoverItemModel(
          alcohol: alcohol,
          globalRating: avg,
          reviewCount: reviews.length,
          hasUserLogged: hasLogged,
          hasUserReviewed: hasReviewed,
        ));
      }

      // Shuffle initially for random
      items.shuffle();

      if (mounted) {
        setState(() {
          _allAlcohols = items;
          _availableTypes = typesList.toList()..sort();
          _isLoading = false;
        });

        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    var result = List<DiscoverItemModel>.from(_allAlcohols);

    // Apply Text Query
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      result = result
          .where((item) =>
              item.alcohol.name.toLowerCase().contains(lowerQuery) ||
              item.alcohol.brand.toLowerCase().contains(lowerQuery) ||
              item.alcohol.type.toLowerCase().contains(lowerQuery))
          .toList();
    }

    // Apply Type Filter
    if (_selectedType != null) {
      result =
          result.where((item) => item.alcohol.type == _selectedType).toList();
    }

    // Apply Sort
    switch (_selectedSort) {
      case DiscoverSortOption.aToZ:
        result.sort((a, b) => a.alcohol.name.compareTo(b.alcohol.name));
        break;
      case DiscoverSortOption.highestRated:
        result.sort((a, b) => b.globalRating.compareTo(a.globalRating));
        break;
      case DiscoverSortOption.mostReviewed:
        result.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case DiscoverSortOption.random:
        // Already shuffled initially. Don't reshuffle to prevent jumpy view.
        break;
    }

    setState(() {
      _filteredAlcohols = result;
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FilterBottomSheet(
          initialSort: _selectedSort,
          initialType: _selectedType,
          availableTypes: _availableTypes,
          onApply: (sort, type) {
            setState(() {
              _selectedSort = sort;
              _selectedType = type;
            });
            _applyFilters();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _error.isNotEmpty
              ? Center(
                  child: Text('Error: $_error',
                      style: TextStyle(color: colorScheme.error)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      // Search Bar
                      child: TextField(
                        controller: _controller,
                        style: textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Search alcohols, brands, types...',
                          hintStyle: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
                          prefixIcon:
                              Icon(Icons.search, color: customColors.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.tune,
                              color: (_selectedType != null ||
                                      _selectedSort !=
                                          DiscoverSortOption.random)
                                  ? colorScheme.primary
                                  : customColors.textMuted,
                            ),
                            onPressed: _openFilterSheet,
                          ),
                          filled: true,
                          fillColor: customColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          _searchQuery = value.trim();
                          _applyFilters();
                        },
                      ),
                    ),
                    Expanded(
                      child: _filteredAlcohols.isEmpty
                          ? AppEmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No results found',
                              subtitle:
                                  'Try searching for something else\nor clearing your filters.',
                              buttonText: 'Clear Search',
                              onAddTap: () {
                                _controller.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedType = null;
                                  _selectedSort = DiscoverSortOption.random;
                                });
                                _applyFilters();
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredAlcohols.length,
                              itemBuilder: (context, index) {
                                return DiscoverAlcoholCard(
                                  item: _filteredAlcohols[index],
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
