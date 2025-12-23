import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drunk_diary/screens/alcohol/alcohol_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/alcohol_model.dart';

class AlcoholSearchScreen extends StatefulWidget {
  static const routeName = '/search';
  const AlcoholSearchScreen({super.key});

  @override
  State<AlcoholSearchScreen> createState() => _AlcoholSearchScreenState();
}

class _AlcoholSearchScreenState extends State<AlcoholSearchScreen> {
  String searchQuery = '';

  Future<List<AlcoholModel>> _fetchAlcohols() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('alcohols')
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => AlcoholModel.fromFirestore(doc))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Alcohols'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, brand, or type',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<AlcoholModel>>(
        future: _fetchAlcohols(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No alcohols found'));
          }

          final alcohols = snapshot.data!;
          
          final filteredAlcohols = alcohols.where((alcohol) {
            return alcohol.name.toLowerCase().contains(searchQuery) ||
                alcohol.brand.toLowerCase().contains(searchQuery) ||
                alcohol.type.toLowerCase().contains(searchQuery);
          }).toList();

          if (filteredAlcohols.isEmpty) {
            return const Center(child: Text('No matching alcohols found'));
          }


          return ListView.separated(
            itemCount: filteredAlcohols.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final alcohol = filteredAlcohols[index];

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: alcohol.imageUrl.isNotEmpty
                      ? Image.network(
                    alcohol.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.local_bar),
                  ),
                ),
                title: Text(alcohol.name),
                subtitle: Text(
                  "${alcohol.brand} • ${alcohol.type} • ${alcohol.abv}% ABV",
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlcoholDetailScreen(
                        alcoholId: alcohol.id,
                        initialAlcohol: alcohol,
                      ),
                    ),
                  );
                },
              );
            },
          );

        },
      ),
    );
  }
}
