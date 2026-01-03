import 'package:drunk_diary/features/profile/screens/public_profile_screen.dart';
import 'package:flutter/material.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/repositories/alcohol_repository.dart';
import '../../alcohol/screens/alcohol_detail_screen.dart';
import '../../profile/models/user_model.dart';
import '../../profile/repositories/profile_repository.dart';
import '../models/search_result.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  final _alcoholRepo = AlcoholRepository();
  final _profileRepo = ProfileRepository();

  String query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Search'),
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),
            // Search Bar
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search alcohols or users',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => query = value.trim().toLowerCase());
              },
            ),

          ),

          Expanded(
            child: query.isEmpty ?
            const Center(

              child: Text('Start typing to search'),

            )
                : FutureBuilder(
              future: _search(query),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final results = snapshot.data!;

                if (results.isEmpty) {
                  return const Center(
                    child: Text('No results found'),
                  );
                }

                return ListView(
                  children: _buildResults(results),
                );
              },
            ),
          ),
        ],

      ),
    );
  }

  // _search()
  Future<List<SearchResultModel>> _search(String query) async {
    final alcohols =
    await _alcoholRepo.searchAlcohols(query);

    final users =
    await _profileRepo.searchPublicUsers(query);

    return [
      ...alcohols.map(
            (alcohol) => SearchResultModel(
          type: SearchResultType.alcohol,
          data: alcohol,
        ),
      ),
      ...users.map(
            (profile) => SearchResultModel(
          type: SearchResultType.profile,
          data: profile,
        ),
      ),
    ];
  }

  // _buildResults()
  List<Widget> _buildResults(List<SearchResultModel> results) {
    final alcoholResults =
    results.where((i) => i.type == SearchResultType.alcohol);
    final userResults =
    results.where((i) => i.type == SearchResultType.profile);

    return [
      if (alcoholResults.isNotEmpty) ...[
        _sectionHeader('Alcohols'),
        ...alcoholResults.map(_buildAlcoholTile),
      ],
      if (userResults.isNotEmpty) ...[
        _sectionHeader('People'),
        ...userResults.map(_buildUserTile),
      ],
    ];
  }

  // _sectionHeader()
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  // _buildAlcoholTile()
  Widget _buildAlcoholTile(SearchResultModel result) {
    final alcohol = result.data as AlcoholModel;

    return ListTile(

      leading: CircleAvatar(
        backgroundImage: // TODO: add thumbnail
        alcohol.imageUrl != null ? NetworkImage(alcohol.imageUrl!) : null,
        child:
        alcohol.imageUrl == null ? const Icon(Icons.local_bar) : null,
      ),

      title: Text(alcohol.name),

      subtitle: Text('${alcohol.brand} • ${alcohol.type}'),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlcoholDetailScreen(alcohol: alcohol),
          ),
        );
      },

    );
  }

  // _buildUserTile()
  Widget _buildUserTile(SearchResultModel result) {
    final user = result.data as UserModel;

    return ListTile(

      leading: CircleAvatar(
        backgroundImage:
        user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child:
        user.photoUrl == null ? const Icon(Icons.person) : null,
      ),

      title: Text(user.displayName),

      subtitle: Text('@${user.username}'),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PublicProfileScreen(username: user.username),
          ),
        );
      },

    );
  }
}
