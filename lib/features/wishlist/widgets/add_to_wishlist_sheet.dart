import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).extension<AppCustomColors>()?.deepCardBackground,
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
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: customColors.deepCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: customColors.borderDark,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            'Add to Wishlist',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search for a drink you\'ve heard of and want to try.',
            style: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
          ),
          const SizedBox(height: 20),

          // Search field
          TextField(
            controller: _searchController,
            style: textTheme.bodyMedium,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search alcohols...',
              hintStyle: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
              prefixIcon: Icon(Icons.search, color: customColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: customColors.textMuted, size: 18),
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
              fillColor: customColors.cardBackground,
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(
                    color: colorScheme.primary, strokeWidth: 2),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: customColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: customColors.borderDark),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: customColors.borderDark, height: 1),
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
                          child: alcohol.imageUrl.isNotEmpty
                              ? Image.network(alcohol.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.local_bar,
                                      color: customColors.textMuted),
                                  // The placeholder property is added here
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: colorScheme.onSurface.withOpacity(0.1),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          color: customColors.textMuted,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Icon(Icons.local_bar, color: customColors.textMuted),
                          color: colorScheme.onSurface.withOpacity(0.1), // This line was moved/modified
                        ),
                      ),
                      title: Text(
                        alcohol.name,
                        style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(
                        '${alcohol.type} · ${alcohol.brand}',
                        style: textTheme.bodySmall?.copyWith(color: customColors.textMuted),
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
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedAlcohol!.name} · ${_selectedAlcohol!.type}',
                      style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Note field
          TextField(
            controller: _noteController,
            style: textTheme.bodyMedium,
            maxLines: 2,
            decoration: InputDecoration(
              hintText:
                  'Add a note (optional)... e.g. "Heard this at Jake\'s party"',
              hintStyle: textTheme.bodyMedium?.copyWith(color: customColors.textMuted),
              prefixIcon: Icon(Icons.sticky_note_2_outlined,
                  color: customColors.textMuted, size: 20),
              filled: true,
              fillColor: customColors.cardBackground,
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
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          ],

          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colorScheme.onPrimary))
                  : Icon(Icons.bookmark_add, color: colorScheme.onPrimary),
              label: Text(
                _isSaving ? 'Adding...' : 'Add to Wishlist',
                style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
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
