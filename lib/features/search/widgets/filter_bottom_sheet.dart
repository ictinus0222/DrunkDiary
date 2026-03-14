import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

enum DiscoverSortOption { random, aToZ, highestRated, mostReviewed }

class FilterBottomSheet extends StatefulWidget {
  final DiscoverSortOption initialSort;
  final String? initialType;
  final List<String> availableTypes;
  final Function(DiscoverSortOption sort, String? type) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialSort,
    required this.initialType,
    required this.availableTypes,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late DiscoverSortOption _selectedSort;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialSort;
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: customColors.deepCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: customColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSort = DiscoverSortOption.random;
                      _selectedType = null;
                    });
                  },
                  child: Text(
                    'Reset',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sort By',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSortChip('Random', DiscoverSortOption.random),
                _buildSortChip('A to Z', DiscoverSortOption.aToZ),
                _buildSortChip(
                    'Highest Rated', DiscoverSortOption.highestRated),
                _buildSortChip(
                    'Most Reviewed', DiscoverSortOption.mostReviewed),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Alcohol Type',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.availableTypes.isEmpty)
              Text('No types available.',
                  style: textTheme.bodyMedium?.copyWith(color: customColors.textMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeChip('All', null),
                  ...widget.availableTypes
                      .map((type) => _buildTypeChip(type, type)),
                ],
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_selectedSort, _selectedType);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, DiscoverSortOption value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedSort = value);
      },
      selectedColor: colorScheme.primary,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: isSelected ? colorScheme.primary : Theme.of(context).extension<AppCustomColors>()!.borderDark),
      ),
    );
  }

  Widget _buildTypeChip(String label, String? value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedType = value);
      },
      selectedColor: colorScheme.primary,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: isSelected ? colorScheme.primary : Theme.of(context).extension<AppCustomColors>()!.borderDark),
      ),
    );
  }
}
