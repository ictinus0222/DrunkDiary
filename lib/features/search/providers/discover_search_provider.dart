import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/providers/alcohol_providers.dart';
import '../../profile/services/user_search_service.dart';

// 1. The Controller - A plain broadcast stream to handle inputs
// Since classic mutable providers like StateProvider are missing in this environment,
// we use a StreamController as the primary input mechanism.
final searchQueryControllerProvider = Provider((ref) {
  final controller = StreamController<String>.broadcast();
  ref.onDispose(() => controller.close());
  return controller;
});

// 2. The Query Stream - Watches the controller and provides the current query
// We use a custom stream that starts with an empty string to avoid AsyncLoading states.
final discoverSearchQueryProvider = StreamProvider<String>((ref) {
  final controller = ref.watch(searchQueryControllerProvider);
  return controller.stream;
});

// 3. People Search Provider - Reactive to the query stream
final peopleSearchProvider = FutureProvider.autoDispose<List<UserSearchResult>>((ref) async {
  // We watch the query stream. Since it's a StreamProvider, this will re-run on every emit.
  final queryAsync = ref.watch(discoverSearchQueryProvider);
  final query = queryAsync.value ?? '';
  
  if (query.trim().length < 2) return [];
  
  // Debounce
  await Future.delayed(const Duration(milliseconds: 300));
  
  final service = UserSearchService();
  return service.searchUsers(query);
});

// 4. Bottle Search Provider - Reactive to the query stream
final bottleSearchProvider = FutureProvider.autoDispose<List<AlcoholSearchResult>>((ref) async {
  final queryAsync = ref.watch(discoverSearchQueryProvider);
  final query = queryAsync.value ?? '';
  
  if (query.trim().length < 2) return [];

  // Debounce
  await Future.delayed(const Duration(milliseconds: 300));

  final results = await ref.read(alcoholRepositoryProvider).searchAlcohols(query);
  final lowercaseQuery = query.toLowerCase().trim();

  return results.map((a) {
    int score = 0;
    if (a.name.toLowerCase() == lowercaseQuery) {
      score = 100;
    } else if (a.name.toLowerCase().startsWith(lowercaseQuery)) {
      score = 70;
    } else {
      score = 30;
    }
    return AlcoholSearchResult(alcohol: a, score: score);
  }).toList();
});

// 5. Combined State Model
class DiscoverSearchState {
  final bool isSearching;
  final List<UserSearchResult> peopleResults;
  final List<AlcoholSearchResult> bottleResults;
  final String query;
  final bool showResults;

  DiscoverSearchState({
    this.isSearching = false,
    this.peopleResults = const [],
    this.bottleResults = const [],
    this.query = '',
    this.showResults = false,
  });

  bool get isEmpty => peopleResults.isEmpty && bottleResults.isEmpty && !isSearching && query.length >= 2;
}

class AlcoholSearchResult {
  final AlcoholModel alcohol;
  final int score;

  AlcoholSearchResult({required this.alcohol, required this.score});
}

// 6. Unified Search Results Provider
// Combines all async inputs into a single UI-friendly state.
final discoverSearchProvider = Provider.autoDispose<DiscoverSearchState>((ref) {
  final queryAsync = ref.watch(discoverSearchQueryProvider);
  final query = queryAsync.value ?? '';
  
  final peopleAsync = ref.watch(peopleSearchProvider);
  final bottlesAsync = ref.watch(bottleSearchProvider);

  final isSearching = peopleAsync.isLoading || bottlesAsync.isLoading;
  final showResults = query.trim().length >= 2;

  return DiscoverSearchState(
    isSearching: isSearching,
    peopleResults: peopleAsync.value ?? [],
    bottleResults: bottlesAsync.value ?? [],
    query: query,
    showResults: showResults,
  );
});
