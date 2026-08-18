import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/encyclopedia_item.dart';
import '../../providers/garden_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/plant_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Category icons
// ─────────────────────────────────────────────────────────────────────────────
const _kCategoryIcons = <String, IconData>{
  'All': Icons.grid_view_rounded,
  'Vegetable': Icons.eco_rounded,
  'Fruit': Icons.apple_rounded,
  'Fruit Tree': Icons.park_rounded,
  'Fruit Vine': Icons.spa_rounded,
  'Houseplant': Icons.home_rounded,
  'Succulent': Icons.wb_sunny_rounded,
  'Herb': Icons.grass_rounded,
  'Flower': Icons.local_florist_rounded,
};

class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  // ── State ─────────────────────────────────────────────────────────────────
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isGridView = true;
  Timer? _debounceTimer;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  final List<String> _categories = [
    'All',
    'Vegetable',
    'Fruit',
    'Fruit Tree',
    'Fruit Vine',
    'Houseplant',
    'Succulent',
    'Herb',
    'Flower',
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.primaryGreen;
      case 'medium':
        return AppTheme.accentAmber;
      case 'hard':
      default:
        return AppTheme.dangerRed;
    }
  }

  double _hPad(double w) {
    if (w < 360) return 16;
    if (w < 428) return 20;
    return 24;
  }

  int _gridColumns(double w) => w >= 600 ? 3 : 2;

  // ── Detail sheet (logic unchanged) ────────────────────────────────────────
  void _showPlantDetailSheet(
      BuildContext context, EncyclopediaItem item, GardenProvider gardenProvider) {
    final diffColor = _getDifficultyColor(item.careDifficulty);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return AppCard(
              borderRadius: 30,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: buildPlantImage(
                      item.imageUrl,
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.commonName,
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.scientificName,
                              style: const TextStyle(color: Colors.white54, fontSize: 15, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: diffColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          item.careDifficulty.toUpperCase(),
                          style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 32),

                  // Quick specs row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSpecItem(Icons.light_mode_rounded, 'SUNLIGHT', item.sunlight, AppTheme.accentAmber),
                      _buildSpecItem(Icons.water_drop_rounded, 'WATERING', item.watering, Colors.blueAccent),
                      _buildSpecItem(Icons.category_rounded, 'CATEGORY', item.category, AppTheme.primaryGreen),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Toxicity alert
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRed.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOXICITY & PET SAFETY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.dangerRed, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(item.toxicity, style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.8), height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white54, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text(item.description, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
                  const SizedBox(height: 24),

                  // Ideal Soil
                  const Text('IDEAL SOIL CONDITIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white54, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text(item.idealSoil, style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
                  const SizedBox(height: 24),

                  // Native Region
                  const Text('NATIVE REGION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white54, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text(item.nativeRegion, style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
                  const SizedBox(height: 24),

                  // Fun Facts list
                  const Text('DID YOU KNOW?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryGreen, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  ...item.funFacts.map((fact) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.star_purple500_rounded, color: AppTheme.primaryGreen, size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Text(fact, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75), height: 1.4))),
                          ],
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpecItem(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
    final allItems = EncyclopediaItem.defaultItems;

    // Filter list — logic unchanged
    final items = allItems.where((item) {
      final matchesSearch = item.commonName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.scientificName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'All' || item.category.toLowerCase().contains(_selectedCategory.toLowerCase());
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Encyclopedia'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: IconButton(
                key: ValueKey(_isGridView),
                icon: Icon(
                  _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: AppColors.onSurfaceMuted,
                ),
                tooltip: _isGridView ? 'Switch to list' : 'Switch to grid',
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkBgGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final hp = _hPad(w);

              return Column(
                children: [
                  // ── Search & Filter ───────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                    child: Column(
                      children: [
                        // Pill search bar
                        _PillSearchBar(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          hintText: 'Search ${EncyclopediaItem.defaultItems.length} plant species…',
                          onChanged: (val) {
                            _debounceTimer?.cancel();
                            _debounceTimer = Timer(
                              const Duration(milliseconds: 300),
                              () => setState(() => _searchQuery = val),
                            );
                          },
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                        const SizedBox(height: 14),

                        // Horizontal category chips
                        SizedBox(
                          height: 42,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = _selectedCategory == cat;
                              final icon = _kCategoryIcons[cat] ?? Icons.label_rounded;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _CategoryChip(
                                  label: cat,
                                  icon: icon,
                                  isSelected: isSelected,
                                  onTap: () => setState(() => _selectedCategory = cat),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Result count row
                        Row(
                          children: [
                            Text(
                              '${items.length} species',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceFaint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // ── Results ───────────────────────────────────────────────
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmptyState()
                        : _isGridView
                            ? _buildGrid(context, items, gardenProvider, hp, w)
                            : _buildList(context, items, gardenProvider, hp),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Grid view ─────────────────────────────────────────────────────────────
  Widget _buildGrid(
    BuildContext context,
    List<EncyclopediaItem> items,
    GardenProvider gardenProvider,
    double hp,
    double w,
  ) {
    final cols = _gridColumns(w);
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(hp, 4, hp, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _PlantGridCard(
          item: item,
          difficultyColor: _getDifficultyColor(item.careDifficulty),
          onTap: () => _showPlantDetailSheet(context, item, gardenProvider),
        )
            .animate()
            .fade(
              delay: Duration(milliseconds: index * 60),
              duration: const Duration(milliseconds: 350),
            )
            .scale(
              begin: const Offset(0.94, 0.94),
              delay: Duration(milliseconds: index * 60),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
      },
    );
  }

  // ── List view ─────────────────────────────────────────────────────────────
  Widget _buildList(
    BuildContext context,
    List<EncyclopediaItem> items,
    GardenProvider gardenProvider,
    double hp,
  ) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(hp, 4, hp, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _PlantListCard(
          item: item,
          difficultyColor: _getDifficultyColor(item.careDifficulty),
          onTap: () => _showPlantDetailSheet(context, item, gardenProvider),
        )
            .animate()
            .fade(
              delay: Duration(milliseconds: index * 50),
              duration: const Duration(milliseconds: 400),
            )
            .slideY(
              begin: 0.06,
              delay: Duration(milliseconds: index * 50),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
      },
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20), width: 1.5),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            )
                .animate()
                .fade(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'No plants found',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate(delay: 100.ms).fade(duration: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 10),
            Text(
              'Try a different search term or\nremove the active category filter.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate(delay: 180.ms).fade(duration: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear filters'),
            ).animate(delay: 260.ms).fade(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill Search Bar
// ─────────────────────────────────────────────────────────────────────────────
class _PillSearchBar extends StatefulWidget {
  const _PillSearchBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_PillSearchBar> createState() => _PillSearchBarState();
}

class _PillSearchBarState extends State<_PillSearchBar> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused ? AppColors.primary : AppColors.border;
    final fillColor = _focused ? AppColors.surfaceHighlight : AppColors.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: const TextStyle(color: AppColors.onSurface, fontSize: 15),
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppColors.onSurfaceFaint, fontSize: 14),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          suffixIcon: widget.controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: widget.onClear,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceHighlight,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.onSurfaceMuted),
                  ),
                )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Chip
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.onSurfaceMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plant Grid Card  (image-forward, 3:4 aspect, gradient overlay)
// ─────────────────────────────────────────────────────────────────────────────
class _PlantGridCard extends StatelessWidget {
  const _PlantGridCard({
    required this.item,
    required this.difficultyColor,
    required this.onTap,
  });

  final EncyclopediaItem item;
  final Color difficultyColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full-bleed plant image
              buildPlantImage(
                item.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),

              // Dark gradient overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 110,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC0D110D)],
                    ),
                  ),
                ),
              ),

              // Bottom: category badge + plant name
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.commonName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                    ),
                  ],
                ),
              ),

              // Top-right: difficulty badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    item.careDifficulty.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plant List Card  (72×72 image, bold name, muted sci-name, category chip)
// ─────────────────────────────────────────────────────────────────────────────
class _PlantListCard extends StatelessWidget {
  const _PlantListCard({
    required this.item,
    required this.difficultyColor,
    required this.onTap,
  });

  final EncyclopediaItem item;
  final Color difficultyColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // 72×72 rounded image
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: buildPlantImage(
                    item.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),

                // Text column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.commonName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.scientificName,
                        style: const TextStyle(
                          color: AppColors.onSurfaceMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.light_mode_rounded,
                              color: AppTheme.accentAmber.withValues(alpha: 0.85), size: 13),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(item.sunlight,
                                style: const TextStyle(
                                    color: AppColors.onSurfaceFaint, fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.water_drop_rounded,
                              color: Colors.blueAccent.withValues(alpha: 0.85), size: 13),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(item.watering,
                                style: const TextStyle(
                                    color: AppColors.onSurfaceFaint, fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Right column: category chip + difficulty dot
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.borderLight, width: 1),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: difficultyColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.careDifficulty,
                          style: TextStyle(
                            color: difficultyColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
