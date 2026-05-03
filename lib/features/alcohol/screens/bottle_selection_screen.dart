import 'package:flutter/material.dart';
import '../../alcohol/models/alcohol_model.dart';
import '../../alcohol/repositories/alcohol_repository.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../app/app_theme.dart';
import '../../../core/widgets/app_shimmer.dart';

class BottleSelectionScreen extends StatefulWidget {
  const BottleSelectionScreen({super.key});

  @override
  State<BottleSelectionScreen> createState() => _BottleSelectionScreenState();
}

class _BottleSelectionScreenState extends State<BottleSelectionScreen> {
  final _alcoholRepo = AlcoholRepository();
  List<AlcoholModel> _allAlcohols = [];
  List<AlcoholModel> _filteredAlcohols = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final alcohols = await _alcoholRepo.getAllAlcohols();
      setState(() {
        _allAlcohols = alcohols;
        _filteredAlcohols = alcohols;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredAlcohols = _allAlcohols.where((a) {
        return a.name.toLowerCase().contains(_searchQuery) ||
            a.brand.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Scaffold(
      backgroundColor: customColors.deepCardBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('SELECT BOTTLE', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              onChanged: _filter,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search bottles...',
                prefixIcon: const Icon(Icons.search, color: Colors.white24),
                filled: true,
                fillColor: customColors.cardBackground,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const _LoadingList()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: _filteredAlcohols.length,
                    separatorBuilder: (_, __) => Divider(color: customColors.borderDark),
                    itemBuilder: (context, index) {
                      final alcohol = _filteredAlcohols[index];
                      return ListTile(
                        onTap: () => Navigator.pop(context, alcohol),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: customColors.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: alcohol.imageUrl.isNotEmpty
                              ? Image.network(alcohol.imageUrl, fit: BoxFit.contain)
                              : const Icon(Icons.local_bar, color: Colors.white24),
                        ),
                        title: Text(alcohol.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(alcohol.brand, style: AppTextStyles.caption.copyWith(color: customColors.textMuted)),
                        trailing: const Icon(Icons.add, color: Colors.amber, size: 20),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppShimmer(height: 60, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
