import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/loading_widgets.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/product_card_widget.dart';
import '../../../providers/product_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      // Load recent searches if available
      // context.read<ProductProvider>().loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    context.read<ProductProvider>().searchProducts(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search products...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: AppColors.textTertiary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                        });
                        context.read<ProductProvider>().clearSearch();
                      },
                    )
                  : null,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _handleSearch,
            onChanged: (value) {
              setState(() {}); // Update to show/hide clear button
            },
          ),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          // 1. Initial State / Recent Searches
          if (!_isSearching && provider.searchResults.isEmpty) {
            return _buildRecentSearches();
          }

          // 2. Loading State
          if (provider.isLoading) {
            return const Center(child: LoadingSpinner());
          }

          // 3. No Results
          if (provider.searchResults.isEmpty) {
            return EmptyStateWidget(
              title: 'No Results Found',
              message:
                  'We couldn\'t find any products matching "${_searchController.text}"',
              icon: Icons.search_off,
            );
          }

          // 4. Results Grid
          return GridView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: AppDimensions.space16,
              mainAxisSpacing: AppDimensions.space16,
            ),
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) {
              return ProductCard(
                product: provider.searchResults[index],
                width: double.infinity,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentSearches() {
    // TODO: Fetch actual recent searches from provider/storage
    final recentSearches = ['Cement', 'Steel Rods', 'Bricks', 'Paint'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Text(
            'Recent Searches',
            style: AppTypography.h6.copyWith(fontWeight: AppTypography.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recentSearches.length,
            itemBuilder: (context, index) {
              final term = recentSearches[index];
              return ListTile(
                leading:
                    const Icon(Icons.history, color: AppColors.textTertiary),
                title: Text(term),
                trailing: const Icon(Icons.north_west, size: 16),
                onTap: () {
                  _searchController.text = term;
                  _handleSearch(term);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
