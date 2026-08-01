import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../models/shop_product.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Pest & Disease Control',
    'Fertilizers & Soil',
    'Gardening Tools',
    'Watering Equipment',
    'Pots & Containers',
    'Indoor Growing',
    'Books & Guides',
  ];

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

  void _shareProduct(ShopProduct product) {
    final String shareText =
        "Check out this gardening recommendation from PlantCare AI:\n\n"
        "${product.title}\n"
        "Price: ${product.price}\n"
        "Rating: ⭐ ${product.rating} (${product.reviewCount} reviews)\n\n"
        "Link: ${product.affiliateUrl}";
    Share.share(shareText, subject: product.title);
  }

  void _showProductDetails(BuildContext context, ShopProduct product, ShopProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return AnimatedBuilder(
              animation: provider,
              builder: (context, _) {
                final isFav = provider.isFavorite(product.id);
                return AppCard(
                  borderRadius: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ListView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Pull Bar & Control Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: Colors.white70),
                            onPressed: () => _shareProduct(product),
                          ),
                          Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? AppTheme.dangerRed : Colors.white70,
                            ),
                            onPressed: () => provider.toggleFavorite(product.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Image Container
                      Center(
                        child: Container(
                          height: 240,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 1.2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                httpHeaders: ShopProduct.amazonImageHeaders,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  enabled: !WidgetsBinding.instance.runtimeType.toString().contains('Test'),
                                  baseColor: AppColors.surfaceHighlight,
                                  highlightColor: AppColors.borderLight,
                                  child: Container(color: AppColors.backgroundLight),
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint('🖼️ Image load FAILED → $url\nError: $error');
                                  return const Center(
                                    child: Icon(
                                      Icons.local_florist_rounded,
                                      color: AppColors.primary,
                                      size: 60,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category tag
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              product.category.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 22,
                          color: AppColors.onSurface,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Price & Rating Info
                      Row(
                        children: [
                          Text(
                            product.price,
                            style: const TextStyle(
                              color: AppColors.accentLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating}',
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${product.reviewCount} reviews)',
                            style: const TextStyle(
                              color: AppColors.onSurfaceMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 28),

                      // Description title
                      const Text(
                        'Product details',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description text
                      Text(
                        product.description,
                        style: const TextStyle(
                          color: AppColors.onSurfaceMuted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Affiliate Disclosure Alert Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'As an Amazon Associate, we earn a commission on qualifying purchases made through our referral links. This helps support the maintenance of PlantCare AI.',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Redirect CTA Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          provider.logClickAndLaunch(product.id, product.asin);
                        },
                        icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                        label: const Text('View on Amazon'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Affiliate Shop 🛒'),
        elevation: 0,
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.onSurfaceMuted,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Wishlist'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // ── Browse Tab ──────────────────────────────────────────
            Column(
              children: [
                _buildSearchAndFilters(context, provider),
                Expanded(
                  child: provider.isLoading
                      ? _buildShimmerGrid()
                      : RefreshIndicator(
                          onRefresh: () => provider.loadProducts(),
                          color: AppColors.primary,
                          child: provider.products.isEmpty
                              ? _buildEmptyState('No products found matching your search.')
                              : GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.64,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: provider.products.length,
                                  itemBuilder: (context, index) {
                                    final product = provider.products[index];
                                    return _buildProductCard(context, product, provider)
                                        .animate()
                                        .fade(duration: 300.ms, delay: (index * 40).ms)
                                        .slideY(begin: 0.05);
                                  },
                                ),
                        ),
                ),
              ],
            ),

            // ── Wishlist Tab ────────────────────────────────────────
            provider.wishlist.isEmpty
                ? _buildEmptyState('Your wishlist is empty. Tap the heart on products to save them!')
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.64,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.wishlist.length,
                    itemBuilder: (context, index) {
                      final product = provider.wishlist[index];
                      return _buildProductCard(context, product, provider)
                          .animate()
                          .fade(duration: 300.ms, delay: (index * 40).ms)
                          .slideY(begin: 0.05);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, ShopProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        children: [
          // Search & Sort row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (val) => provider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search supplies...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort PopupMenu
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                  tooltip: 'Sort Products',
                  onSelected: (mode) => provider.setSortMode(mode),
                  color: AppColors.surfaceElevated,
                  itemBuilder: (context) => [
                    'Popularity',
                    'Rating',
                    'Price: Low to High',
                    'Price: High to Low',
                  ].map((mode) {
                    final isSelected = provider.sortMode == mode;
                    return PopupMenuItem<String>(
                      value: mode,
                      child: Text(
                        mode,
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryLight : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable Categories chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = provider.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setSelectedCategory(cat);
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurfaceMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ShopProduct product, ShopProvider provider) {
    final isFav = provider.isFavorite(product.id);
    return GestureDetector(
      onTap: () => _showProductDetails(context, product, provider),
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: 18,
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with favorite heart and verified badge overlays
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          httpHeaders: ShopProduct.amazonImageHeaders,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Shimmer.fromColors(
                            enabled: !WidgetsBinding.instance.runtimeType.toString().contains('Test'),
                            baseColor: AppColors.surfaceHighlight,
                            highlightColor: AppColors.borderLight,
                            child: Container(color: AppColors.backgroundLight),
                          ),
                          errorWidget: (context, url, error) {
                            debugPrint('🖼️ Grid image FAILED → $url\nError: $error');
                            return const Center(
                              child: Icon(
                                Icons.local_florist_rounded,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Verified badge — top left
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.white, size: 10),
                            SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Favorite Heart Toggle Overlay
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => provider.toggleFavorite(product.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppTheme.dangerRed : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Metadata area
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Text(
                    product.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Price & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.price,
                        style: const TextStyle(
                          color: AppColors.accentLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating}',
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          enabled: !WidgetsBinding.instance.runtimeType.toString().contains('Test'),
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceHighlight,
          child: AppCard(
            padding: EdgeInsets.zero,
            borderRadius: 18,
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 10, width: 60, color: Colors.white10),
                      const SizedBox(height: 8),
                      Container(height: 14, width: double.infinity, color: Colors.white10),
                      const SizedBox(height: 4),
                      Container(height: 14, width: 80, color: Colors.white10),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(height: 16, width: 40, color: Colors.white10),
                          Container(height: 16, width: 30, color: Colors.white10),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
