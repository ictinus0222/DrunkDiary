import 'package:flutter/material.dart';

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
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
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
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
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
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort By',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
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
            const Text(
              'Alcohol Type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.availableTypes.isEmpty)
              Text('No types available.',
                  style: TextStyle(color: Colors.grey.shade500))
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
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
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
    final isSelected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedSort = value);
      },
      selectedColor: Colors.amber,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.amber : Colors.grey),
      ),
    );
  }

  Widget _buildTypeChip(String label, String? value) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedType = value);
      },
      selectedColor: Colors.amber,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.amber : Colors.grey),
      ),
    );
  }
}
