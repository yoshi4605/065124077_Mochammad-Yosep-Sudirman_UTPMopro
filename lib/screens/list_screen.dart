import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';
import '../widgets/earthquake_card.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

/// Halaman Daftar Gempa: TabBar M 5.0+ & Dirasakan beserta fitur pencarian wilayah
class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eqProvider = Provider.of<EarthquakeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Gempa'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan nama wilayah/kota...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              eqProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: (value) => eqProvider.setSearchQuery(value),
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.warning_amber_rounded, size: 20),
                    text: 'M 5.0+ (15 Gempa)',
                  ),
                  Tab(
                    icon: Icon(Icons.vibration_rounded, size: 20),
                    text: 'Dirasakan (15 Gempa)',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: M 5.0+
          _buildEarthquakeList(
            context,
            isLoading: eqProvider.isLoadingRecent,
            errorMessage: eqProvider.errorRecent,
            items: eqProvider.filteredRecentEarthquakes,
            onRefresh: () => eqProvider.fetchRecent(),
            emptyMessage: eqProvider.searchQuery.isNotEmpty
                ? 'Tidak ada gempa M 5.0+ dengan wilayah "${eqProvider.searchQuery}".'
                : 'Tidak ada data gempa M 5.0+ saat ini.',
          ),
          // Tab 2: Dirasakan
          _buildEarthquakeList(
            context,
            isLoading: eqProvider.isLoadingFelt,
            errorMessage: eqProvider.errorFelt,
            items: eqProvider.filteredFeltEarthquakes,
            onRefresh: () => eqProvider.fetchFelt(),
            emptyMessage: eqProvider.searchQuery.isNotEmpty
                ? 'Tidak ada gempa dirasakan dengan wilayah "${eqProvider.searchQuery}".'
                : 'Tidak ada data gempa dirasakan saat ini.',
          ),
        ],
      ),
    );
  }

  Widget _buildEarthquakeList(
    BuildContext context, {
    required bool isLoading,
    required String? errorMessage,
    required List<Earthquake> items,
    required Future<void> Function() onRefresh,
    required String emptyMessage,
  }) {
    if (isLoading && items.isEmpty) {
      return const LoadingView(message: 'Memuat data gempa BMKG...');
    }

    if (errorMessage != null && items.isEmpty) {
      return ErrorView(
        message: errorMessage,
        onRetry: onRefresh,
      );
    }

    if (items.isEmpty) {
      return EmptyView(
        icon: Icons.search_off_rounded,
        title: 'Data Tidak Ditemukan',
        message: emptyMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final eq = items[index];
          return EarthquakeCard(earthquake: eq);
        },
      ),
    );
  }
}
