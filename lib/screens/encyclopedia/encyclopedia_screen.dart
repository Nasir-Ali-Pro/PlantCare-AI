import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/encyclopedia_item.dart';
import '../../providers/garden_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/plant_image.dart';



class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Timer? _debounceTimer;

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

  void _showPlantDetailSheet(BuildContext context, EncyclopediaItem item, GardenProvider gardenProvider) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
    final allItems = EncyclopediaItem.defaultItems;

    // Filter list
    final items = allItems.where((item) {
      final matchesSearch = item.commonName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.scientificName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'All' || item.category.toLowerCase().contains(_selectedCategory.toLowerCase());
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Encyclopedia'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkBgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Search & Filter Bars ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) {
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                          setState(() {
                            _searchQuery = val;
                          });
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search ${EncyclopediaItem.defaultItems.length} plant species...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white12, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Horizontal Filter list
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryGreen,
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.04),
                              shadowColor: Colors.transparent,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryGreen : Colors.white12,
                                  width: 1.0,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Encyclopedia Results List ─────────────────────────────────────
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final diffColor = _getDifficultyColor(item.careDifficulty);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () => _showPlantDetailSheet(context, item, gardenProvider),
                              borderRadius: BorderRadius.circular(20),
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                borderRadius: 20,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: buildPlantImage(
                                        item.imageUrl,
                                        width: 68,
                                        height: 68,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.commonName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                item.careDifficulty.toUpperCase(),
                                                style: TextStyle(color: diffColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.scientificName,
                                            style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.light_mode_rounded, color: AppTheme.accentAmber.withValues(alpha: 0.8), size: 13),
                                              const SizedBox(width: 4),
                                              Text(item.sunlight, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                              const SizedBox(width: 12),
                                              Icon(Icons.water_drop_rounded, color: Colors.blueAccent.withValues(alpha: 0.8), size: 13),
                                              const SizedBox(width: 4),
                                              Text(item.watering, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fade(delay: (index * 50).ms, duration: 400.ms).slideY(begin: 0.05);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 60,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No plants found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try typing a different name or search keyword (e.g. "Tomato", "Strawberry").',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white30,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
