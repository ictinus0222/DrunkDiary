import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/repositories/alcohol_repository.dart';
import '../repositories/wishlist_repository.dart';

class AddToWishlistSheet extends StatefulWidget {
  const AddToWishlistSheet({super.key});

  @override
  State<AddToWishlistSheet> createState() => _AddToWishlistSheetState();
}

class _AddToWishlistSheetState extends State<AddToWishlistSheet> {
  final _searchController = TextEditingController();
  final _noteController = TextEditingController();
  final _alcoholRepo = AlcoholRepository();
  final _wishlistRepo = WishlistRepository();

  List<AlcoholModel> _searchResults = [];
  AlcoholModel? _selectedAlcohol;
  bool _isSearching = false;
  bool _isSaving = false;
  String _error = '';

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _alcoholRepo.searchAlcohols(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectAlcohol(AlcoholModel alcohol) {
    setState(() {
      _selectedAlcohol = alcohol;
      _searchResults = [];
      _searchController.text = alcohol.name;
      _error = '';
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _save() async {
    if (_selectedAlcohol == null) {
      setState(() => _error = 'Please search and select an alcohol first.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = '';
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _wishlistRepo.addToWishlist(
        userId: userId,
        alcohol: _selectedAlcohol!,
        note: _noteController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedAlcohol!.name} added to your wishlist!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().contains('already_in_wishlist')
              ? 'This drink is already in your wishlist!'
              : 'Something went wrong. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Text(
            'Add to Wishlist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search for a drink you\'ve heard of and want to try.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Search field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search alcohols...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _selectedAlcohol = null;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() => _selectedAlcohol = null);
              _onSearchChanged(val);
            },
          ),

          // Search results
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(
                    color: Colors.amber, strokeWidth: 2),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey.shade800, height: 1),
                  itemBuilder: (context, index) {
                    final alcohol = _searchResults[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 44,
                          color: Colors.white10,
                          child: alcohol.imageUrl.isNotEmpty
                              ? Image.network(alcohol.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.local_bar,
                                      color: Colors.grey))
                              : const Icon(Icons.local_bar, color: Colors.grey),
                        ),
                      ),
                      title: Text(
                        alcohol.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${alcohol.type} · ${alcohol.brand}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                      onTap: () => _selectAlcohol(alcohol),
                    );
                  },
                ),
              ),
            )
          else if (_selectedAlcohol != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedAlcohol!.name} · ${_selectedAlcohol!.type}',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Note field
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              hintText:
                  'Add a note (optional)... e.g. "Heard this at Jake\'s party"',
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              prefixIcon: const Icon(Icons.sticky_note_2_outlined,
                  color: Colors.grey, size: 20),
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (_error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],

          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.bookmark_add, color: Colors.black),
              label: Text(
                _isSaving ? 'Adding...' : 'Add to Wishlist',
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                disabledBackgroundColor: Colors.amber.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
