import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/product/product_card_grid.dart';
import '../../config/app_constants.dart';
import '../../config/app_colors.dart';

class ModernSearchScreen extends ConsumerStatefulWidget {
  const ModernSearchScreen({super.key});

  @override
  ConsumerState<ModernSearchScreen> createState() => _ModernSearchScreenState();
}

class _ModernSearchScreenState extends ConsumerState<ModernSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _selectedFilter = 'All';
  String _selectedSort = 'Featured';

  final _recentSearches = [
    'Cement 50kg',
    'Steel bars',
    'Bricks',
    'Paint white',
  ];

  final _trendingSearches = [
    'Portland Cement',
    'TMT Steel',
    'Red Bricks',
    'Emulsion Paint',
    'Power Tools',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Search Header
            _buildSearchHeader(theme, isDark),

            // Search Content
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildSearchSuggestions(theme, isDark)
                  : _buildSearchResults(theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: AppConstants.paddingAll16,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppConstants.borderRadiusLarge,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.primaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() => _searchController.clear());
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showFilterSheet(),
                icon: const Icon(Icons.tune, color: Colors.white),
              ),
            ],
          ),

          // Quick Filters
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQuickFilterChip('All'),
                  _buildQuickFilterChip('In Stock'),
                  _buildQuickFilterChip('On Sale'),
                  _buildQuickFilterChip('Featured'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = label);
        },
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        selectedColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildSearchSuggestions(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: AppConstants.paddingAll20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            SectionHeader(
              title: 'Recent Searches',
              actionText: 'Clear',
              onSeeAll: () {
                setState(() => _recentSearches.clear());
              },
            ),
            const SizedBox(height: 12),
            ..._recentSearches.map((search) => _buildSearchSuggestionTile(
                  search,
                  Icons.history,
                  theme,
                  isDark,
                )),
            const SizedBox(height: 24),
          ],

          // Trending Searches
          const SectionHeader(
            title: 'Trending Searches',
          ),
          const SizedBox(height: 12),
          ..._trendingSearches.map((search) => _buildSearchSuggestionTile(
                search,
                Icons.trending_up,
                theme,
                isDark,
              )),
          const SizedBox(height: 24),

          // Popular Categories
          const SectionHeader(
            title: 'Popular Categories',
          ),
          const SizedBox(height: 12),
          _buildCategoriesGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestionTile(
    String text,
    IconData icon,
    ThemeData theme,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        setState(() => _searchController.text = text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppConstants.borderRadiusSmall,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.north_west,
                size: 16, color: AppColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(bool isDark) {
    final categories = [
      {'name': 'Cement', 'icon': Icons.construction},
      {'name': 'Steel', 'icon': Icons.straighten},
      {'name': 'Bricks', 'icon': Icons.view_module},
      {'name': 'Paint', 'icon': Icons.palette},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            setState(() => _searchController.text = category['name'] as String);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.1),
                  AppColors.secondaryPurple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: AppConstants.borderRadiusMedium,
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category['icon'] as IconData,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(ThemeData theme, bool isDark) {
    // Mock search results
    final products = List.generate(
      8,
      (index) => Product(
        id: 'prod_$index',
        title: 'Search Result ${index + 1}',
        description: 'High quality building material product',
        price: 500.0 + (index * 100),
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        stock: 50,
        images: [],
        createdAt: DateTime.now(),
      ),
    );

    return Column(
      children: [
        // Sort Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${products.length} results found',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showSortSheet(),
                icon: const Icon(Icons.sort, size: 18),
                label: Text(_selectedSort),
              ),
            ],
          ),
        ),

        // Results Grid
        Expanded(
          child: GridView.builder(
            padding: AppConstants.paddingAll16,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCardGrid(
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppConstants.paddingAll20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            // Add filter options here
            const Text('Price Range, Ratings, etc.'),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    final sortOptions = [
      'Featured',
      'Price: Low to High',
      'Price: High to Low',
      'Newest',
      'Best Rating',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppConstants.paddingAll20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ...sortOptions.map((option) => ListTile(
                  title: Text(option),
                  trailing: _selectedSort == option
                      ? const Icon(Icons.check, color: AppColors.primaryBlue)
                      : null,
                  onTap: () {
                    setState(() => _selectedSort = option);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
