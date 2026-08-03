import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/garden_plant.dart';
import '../../providers/garden_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/plant_image.dart';
import '../../widgets/plant_list_card.dart';
import '../../widgets/plant_grid_card.dart';
import '../../widgets/add_plant_sheet.dart';
import '../../widgets/health_painters.dart';
import '../../services/image_service.dart';
import '../forum/forum_screen.dart';



// ─── Main Screen ─────────────────────────────────────────────
class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({super.key});

  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends State<MyGardenScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  String _activeFilter = 'All';
  String _sortMode = 'Name';
  bool _isGridView = false;

  final _searchController = TextEditingController();

  // ── Helpers ──────────────────────────────────────────────
  Color _getHealthColor(int score) {
    if (score >= 70) return AppTheme.primaryGreen;
    if (score >= 40) return AppTheme.accentAmber;
    return AppTheme.dangerRed;
  }

  String _getHealthLabel(int score) {
    if (score >= 70) return 'Healthy';
    if (score >= 40) return 'Fair';
    return 'Critical';
  }

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);



  InputDecoration _buildInputDecoration(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
    );
  }

  void _showActionSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 80),
      ),
    );
  }

  List<GardenPlant> _getFilteredAndSortedPlants(GardenProvider provider) {
    var plants = List<GardenPlant>.from(provider.plants);

    // Filter
    if (_activeFilter == 'Healthy') {
      plants = plants.where((p) => p.computedHealthScore >= 70 && !p.needsWatering && !p.needsFertilizing).toList();
    } else if (_activeFilter == 'Thirsty') {
      plants = plants.where((p) => p.needsWatering).toList();
    } else if (_activeFilter == 'Fertilize') {
      plants = plants.where((p) => p.needsFertilizing).toList();
    } else if (_activeFilter == 'Critical') {
      plants = plants.where((p) => p.computedHealthScore < 40).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      plants = plants.where((p) =>
          p.nickname.toLowerCase().contains(q) ||
          p.species.toLowerCase().contains(q)).toList();
    }

    // Sort
    switch (_sortMode) {
      case 'Health':
        plants.sort((a, b) => a.computedHealthScore.compareTo(b.computedHealthScore));
        break;
      case 'Urgency':
        plants.sort((a, b) => b.careUrgency.compareTo(a.careUrgency));
        break;
      case 'Recent':
        plants.sort((a, b) => b.dateAcquired.compareTo(a.dateAcquired));
        break;
      default: // Name
        plants.sort((a, b) => a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase()));
    }

    return plants;
  }


  // ── Build Methods ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.darkBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.yard_rounded, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              Text('My Garden', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.alarm_rounded,
                color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                size: 22,
              ),
              tooltip: 'Reminder Time',
              onPressed: () async {
                final provider = Provider.of<GardenProvider>(context, listen: false);
                final initialTime = TimeOfDay(
                  hour: provider.reminderHour,
                  minute: provider.reminderMinute,
                );
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initialTime,
                  helpText: 'SET DAILY REMINDER TIME',
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: AppTheme.primaryGreen,
                          onPrimary: Colors.white,
                          surface: const Color(0xFF1E293B),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  await provider.setReminderTime(picked.hour, picked.minute);
                  if (context.mounted) {
                    final timeStr = picked.format(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Daily care reminders set to $timeStr'),
                        backgroundColor: AppTheme.primaryGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.forum_rounded, color: Colors.white70),
              tooltip: 'Community Forum',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumScreen())),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
              tooltip: 'Add Plant',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddPlantSheet(
                  provider: Provider.of<GardenProvider>(context, listen: false),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Consumer<GardenProvider>(
            builder: (context, provider, _) {
              if (provider.plants.isEmpty) {
                return _buildEmptyState(context);
              }
              final filteredPlants = _getFilteredAndSortedPlants(provider);

              return CustomScrollView(
                slivers: [
                  // Stats Dashboard
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: _buildStatsRow(provider),
                  )),

                  // Search, Filter, Sort
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _buildSearchFilterBar(),
                  )),
                  // Plant count label
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      children: [
                        Text(
                          '${filteredPlants.length} PLANT${filteredPlants.length != 1 ? 'S' : ''}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const Spacer(),
                        if (_activeFilter != 'All')
                          GestureDetector(
                            onTap: () => setState(() => _activeFilter = 'All'),
                            child: Text('Clear Filter', style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  )),
                  // Plants Collection
                  if (filteredPlants.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text('No plants match your filter', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_isGridView)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => PlantGridCard(
                            plant: filteredPlants[index],
                            provider: provider,
                            index: index,
                            onTap: () => _showPlantDetailSheet(context, filteredPlants[index], provider),
                          ),
                          childCount: filteredPlants.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: PlantListCard(
                              plant: filteredPlants[index],
                              provider: provider,
                              index: index,
                              onTap: () => _showPlantDetailSheet(context, filteredPlants[index], provider),
                              onAddJournal: () {
                                // Re-fetch live plant from provider to avoid stale snapshot
                                final livePlant = provider.plants.firstWhere(
                                  (p) => p.id == filteredPlants[index].id,
                                  orElse: () => filteredPlants[index],
                                );
                                _showAddJournalDialog(context, livePlant, provider);
                              },
                              onDelete: () => _showDeleteConfirmation(context, filteredPlants[index], provider),
                            ),
                          ),
                          childCount: filteredPlants.length,
                        ),
                      ),
                    ),
                  // Bottom padding for nav bar
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Stats Dashboard ──────────────────────────────────────
  Widget _buildStatsRow(GardenProvider provider) {
    final stats = [
      _StatItem(Icons.eco_rounded, '${provider.plants.length}', 'Plants', AppTheme.primaryGreen),
      _StatItem(Icons.favorite_rounded, '${provider.averageHealthScore.toInt()}%', 'Health', _getHealthColor(provider.averageHealthScore.toInt())),
      _StatItem(Icons.warning_amber_rounded, '${provider.needsCareCount}', 'Need Care', AppTheme.accentAmber),
      _StatItem(Icons.report_problem_rounded, '${provider.criticalPlantCount}', 'Critical', AppTheme.dangerRed),
      _StatItem(Icons.menu_book_rounded, '${provider.totalJournalEntries}', 'Journal', const Color(0xFFA78BFA)),
    ];

    return Row(
      children: List.generate(stats.length, (i) {
        final s = stats[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < stats.length - 1 ? 8 : 0),
            child: AppCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, color: s.color, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    s.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fade(duration: 400.ms, delay: (80 * i).ms).slideY(begin: 0.15, end: 0, duration: 400.ms, delay: (80 * i).ms),
        );
      }),
    );
  }



  // ── Search / Filter / Sort Bar ───────────────────────────
  Widget _buildSearchFilterBar() {
    final filters = [
      _FilterChip('All', null),
      _FilterChip('Healthy', Icons.check_circle_rounded),
      _FilterChip('Thirsty', Icons.water_drop_rounded),
      _FilterChip('Fertilize', Icons.science_rounded),
      _FilterChip('Critical', Icons.warning_amber_rounded),
    ];

    return Column(
      children: [
        // Search row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search plants...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.4), size: 18),
                          onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.2)),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(width: 10),
            // Sort button
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  
                ),
                child: Icon(Icons.sort_rounded, color: Colors.white.withValues(alpha: 0.6), size: 20),
              ),
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (val) => setState(() => _sortMode = val),
              itemBuilder: (_) => [
                _buildSortItem('Name', 'Name A-Z', Icons.sort_by_alpha_rounded),
                _buildSortItem('Health', 'Health ↓', Icons.favorite_rounded),
                _buildSortItem('Urgency', 'Urgency ↑', Icons.priority_high_rounded),
                _buildSortItem('Recent', 'Recent', Icons.schedule_rounded),
              ],
            ),
            const SizedBox(width: 6),
            // Grid/List toggle
            GestureDetector(
              onTap: () => setState(() => _isGridView = !_isGridView),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    key: ValueKey(_isGridView),
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final f = filters[index];
              final isActive = _activeFilter == f.label;
              return GestureDetector(
                onTap: () => setState(() => _activeFilter = f.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryGreen.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppTheme.primaryGreen.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (f.icon != null) ...[
                        Icon(f.icon, size: 14, color: isActive ? AppTheme.primaryGreen : Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 5),
                      ],
                      Text(f.label, style: TextStyle(
                        fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? AppTheme.primaryGreen : Colors.white.withValues(alpha: 0.6),
                      )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fade(duration: 350.ms, delay: 400.ms);
  }

  PopupMenuItem<String> _buildSortItem(String value, String label, IconData icon) {
    final isActive = _sortMode == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isActive ? AppTheme.primaryGreen : Colors.white60),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: isActive ? AppTheme.primaryGreen : Colors.white, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          if (isActive) ...[const Spacer(), const Icon(Icons.check_rounded, size: 16, color: AppTheme.primaryGreen)],
        ],
      ),
    );
  }


  // ── Plant Detail Sheet ───────────────────────────────────
  void _showPlantDetailSheet(BuildContext context, GardenPlant plant, GardenProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Re-fetch plant from provider for live updates
            final currentPlant = provider.plants.firstWhere(
              (p) => p.id == plant.id,
              orElse: () => plant,
            );
            final healthColor = _getHealthColor(currentPlant.computedHealthScore);

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              maxChildSize: 0.95,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return AppCard(
                  borderRadius: 28,
                  
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Drag handle
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            // ─ Plant Image Header
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    currentPlant.imagePath.isNotEmpty && (kIsWeb || File(currentPlant.imagePath).existsSync())
                                        ? buildPlantImage(currentPlant.imagePath, fit: BoxFit.cover)
                                        : Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(colors: [Color(0xFF1A3A2A), Color(0xFF0A1F14)]),
                                            ),
                                            child: Center(child: Icon(Icons.yard_rounded, size: 72, color: AppTheme.primaryGreen.withValues(alpha: 0.3))),
                                          ),
                                    // Gradient overlay for text
                                    Positioned(
                                      bottom: 0, left: 0, right: 0,
                                      child: Container(
                                        height: 80,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Plant name overlay
                                    Positioned(
                                      bottom: 14, left: 16,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(currentPlant.nickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                                          Text(currentPlant.species, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ─ Info Section
                            AppCard(
                              borderRadius: 18,
                              
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PLANT INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.5))),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(Icons.grass_rounded, 'Species', currentPlant.species),
                                  _buildInfoRow(Icons.science_rounded, 'Scientific', currentPlant.scientificName),
                                  _buildInfoRow(Icons.calendar_today_rounded, 'Acquired', _formatDate(currentPlant.dateAcquired)),
                                  if (currentPlant.notes.isNotEmpty)
                                    _buildInfoRow(Icons.notes_rounded, 'Notes', currentPlant.notes),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ─ Health Section
                            AppCard(
                              borderRadius: 18,
                              
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('HEALTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.5))),
                                      const Spacer(),
                                      Text(
                                        _getHealthLabel(currentPlant.computedHealthScore),
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: healthColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${currentPlant.computedHealthScore}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: healthColor)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      height: 10,
                                      child: LinearProgressIndicator(
                                        value: currentPlant.computedHealthScore / 100,
                                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                                        valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('HEALTH HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.4))),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 80,
                                    width: double.infinity,
                                    child: currentPlant.healthHistory.isNotEmpty
                                        ? CustomPaint(
                                            painter: HealthHistoryPainter(
                                              history: currentPlant.healthHistory,
                                              lineColor: healthColor,
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              'No history yet — keep caring for your plant!',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ─ Care Schedule
                            AppCard(
                              borderRadius: 18,
                              
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CARE SCHEDULE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.5))),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(child: _buildCareCountdown(
                                        icon: Icons.water_drop_rounded,
                                        label: 'Watering',
                                        daysLeft: currentPlant.daysUntilWatering,
                                        frequency: currentPlant.wateringFrequencyDays,
                                        isOverdue: currentPlant.needsWatering,
                                        color: const Color(0xFF38BDF8),
                                      )),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildCareCountdown(
                                        icon: Icons.science_rounded,
                                        label: 'Fertilizing',
                                        daysLeft: currentPlant.daysUntilFertilizing,
                                        frequency: currentPlant.fertilizingFrequencyDays,
                                        isOverdue: currentPlant.needsFertilizing,
                                        color: AppTheme.accentAmber,
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            provider.waterPlant(currentPlant.id);
                                            setModalState(() {});
                                            _showActionSnackBar(context, '💧 Plant watered.', AppTheme.primaryDarkGreen);
                                          },
                                          icon: const Icon(Icons.water_drop_rounded, size: 18),
                                          label: const Text('Water Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            provider.fertilizePlant(currentPlant.id);
                                            setModalState(() {});
                                            _showActionSnackBar(context, '🧪 Plant fertilized.', const Color(0xFFB45309));
                                          },
                                          icon: const Icon(Icons.science_rounded, size: 18),
                                          label: const Text('Fertilize', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.accentAmber,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ─ Push Reminders Card
                            AppCard(
                              borderRadius: 18,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        currentPlant.notificationsEnabled
                                            ? Icons.notifications_active_rounded
                                            : Icons.notifications_off_rounded,
                                        size: 16,
                                        color: currentPlant.notificationsEnabled
                                            ? AppTheme.primaryGreen
                                            : Colors.white.withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'PUSH REMINDERS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      const Spacer(),
                                      Switch(
                                        value: currentPlant.notificationsEnabled,
                                        activeThumbColor: AppTheme.primaryGreen,
                                        onChanged: (val) {
                                          provider.togglePlantNotifications(currentPlant.id);
                                          setModalState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    currentPlant.notificationsEnabled
                                        ? 'Daily notifications scheduled for ${TimeOfDay(hour: provider.reminderHour, minute: provider.reminderMinute).format(context)}'
                                        : 'Notifications are muted for this plant.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: currentPlant.notificationsEnabled
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  if (currentPlant.notificationsEnabled) ...[
                                    const SizedBox(height: 10),
                                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.water_drop_rounded, size: 14, color: AppTheme.primaryGreen),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Next Water: ',
                                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                                        ),
                                        Text(
                                          _formatDate(currentPlant.lastWatered.add(Duration(days: currentPlant.wateringFrequencyDays))),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.science_rounded, size: 14, color: AppTheme.accentAmber),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Next Fertilize: ',
                                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                                        ),
                                        Text(
                                          _formatDate(currentPlant.lastFertilized.add(Duration(days: currentPlant.fertilizingFrequencyDays))),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ─ Growth Journal
                            AppCard(
                              borderRadius: 18,
                              
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('GROWTH JOURNAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.5))),
                                      const Spacer(),
                                      Text('${currentPlant.journal.length} entries', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () async {
                                          await _showAddJournalDialog(context, currentPlant, provider);
                                          // Refresh the detail sheet to show the new entry
                                          setModalState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                            
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add_rounded, size: 14, color: AppTheme.primaryGreen),
                                              const SizedBox(width: 4),
                                              Text('Add', style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  if (currentPlant.journal.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(Icons.menu_book_rounded, size: 32, color: Colors.white.withValues(alpha: 0.2)),
                                            const SizedBox(height: 8),
                                            Text('No journal entries yet', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ...currentPlant.journal.asMap().entries.map((entry) {
                                      final i = entry.key;
                                      final j = entry.value;
                                      final isLast = i == currentPlant.journal.length - 1;
                                      return Dismissible(
                                        key: ValueKey(j.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 16),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dangerRed.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.delete_rounded, color: AppTheme.dangerRed),
                                        ),
                                        onDismissed: (_) {
                                          provider.deleteJournalEntry(currentPlant.id, j.id);
                                          setModalState(() {});
                                        },
                                        child: _buildJournalTimelineEntry(j, isLast),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ─ Danger Zone
                            AppCard(
                              borderRadius: 18,
                              
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MANAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.5))),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _showEditPlantSheet(context, currentPlant, provider);
                                          },
                                          icon: const Icon(Icons.edit_rounded, size: 16),
                                          label: const Text('Edit Plant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white70,
                                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _showDeleteConfirmation(context, currentPlant, provider);
                                          },
                                          icon: const Icon(Icons.delete_rounded, size: 16),
                                          label: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.dangerRed,
                                            side: BorderSide(color: AppTheme.dangerRed.withValues(alpha: 0.4)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          SizedBox(
            width: 75,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45), fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildCareCountdown({
    required IconData icon,
    required String label,
    required int daysLeft,
    required int frequency,
    required bool isOverdue,
    required Color color,
  }) {
    final progress = isOverdue ? 1.0 : (1.0 - daysLeft / frequency).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        
      ),
      child: Column(
        children: [
          SizedBox(
            width: 50, height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(50, 50),
                  painter: HealthRingPainter(
                    progress: progress,
                    color: isOverdue ? AppTheme.dangerRed : color,
                    strokeWidth: 3.5,
                  ),
                ),
                Icon(icon, size: 20, color: isOverdue ? AppTheme.dangerRed : color),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOverdue ? 'Overdue!' : '${daysLeft}d left',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isOverdue ? AppTheme.dangerRed : Colors.white),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.45))),
        ],
      ),
    );
  }

  Widget _buildJournalTimelineEntry(JournalEntry entry, bool isLast) {
    final hasMilestone = entry.milestone != null && entry.milestone!.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (hasMilestone)
                  Container(
                    width: 22, height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentAmber.withValues(alpha: 0.15),
                      border: Border.all(color: AppTheme.accentAmber, width: 1.5),
                    ),
                    child: Text(
                      _getMilestoneEmoji(entry.milestone!),
                      style: const TextStyle(fontSize: 11),
                    ),
                  )
                else
                  Container(
                    width: 10, height: 10,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryGreen,
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 2),
                    ),
                  ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Entry content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(entry.dateTime),
                        style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w600),
                      ),
                      if (hasMilestone) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Text(
                            entry.milestone!,
                            style: const TextStyle(fontSize: 9, color: AppTheme.accentAmber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(entry.note, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), height: 1.4)),
                  if (entry.imagePath != null && entry.imagePath!.isNotEmpty && (kIsWeb || File(entry.imagePath!).existsSync()))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: buildPlantImage(entry.imagePath!, height: 80, width: 80, fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMilestoneEmoji(String milestone) {
    if (milestone.contains('🌸')) return '🌸';
    if (milestone.contains('🌱')) return '🌱';
    if (milestone.contains('✂️')) return '✂️';
    if (milestone.contains('🌿')) return '🌿';
    if (milestone.contains('🍂')) return '🍂';
    if (milestone.contains('🪴')) return '🪴';
    if (milestone.contains('🍎')) return '🍎';
    return '🏆';
  }


  Widget _buildImageSourceOption(BuildContext context, IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              
            ),
            child: Icon(icon, size: 32, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Edit Plant Sheet ─────────────────────────────────────
  void _showEditPlantSheet(BuildContext context, GardenPlant plant, GardenProvider provider) {
    final nameCtrl = TextEditingController(text: plant.nickname);
    final speciesCtrl = TextEditingController(text: plant.species);
    final sciCtrl = TextEditingController(text: plant.scientificName.endsWith(' sp.') ? '' : plant.scientificName);
    final notesCtrl = TextEditingController(text: plant.notes);
    int waterFreq = plant.wateringFrequencyDays;
    int fertFreq = plant.fertilizingFrequencyDays;
    int editedHealth = plant.computedHealthScore;
    String currentImagePath = plant.imagePath;
    XFile? pickedImageFile;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: AppCard(
                borderRadius: 30,
                
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text('Edit Plant', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white70)),
                        ],
                      ),
                      Divider(color: Colors.white.withValues(alpha: 0.1), height: 24),

                      // Photo
                      GestureDetector(
                        onTap: () async {
                          final source = await showModalBottomSheet<ImageSource>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AppCard(
                              borderRadius: 24,  padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Change Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildImageSourceOption(context, Icons.camera_alt_rounded, 'Camera', ImageSource.camera),
                                      _buildImageSourceOption(context, Icons.photo_library_rounded, 'Gallery', ImageSource.gallery),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          );
                          if (source != null) {
                            final picked = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 85);
                            if (picked != null) {
                              setModalState(() {
                                pickedImageFile = picked;
                                currentImagePath = picked.path;
                              });
                            }
                          }
                        },
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                          ),
                          child: currentImagePath.isNotEmpty
                              ? ClipRRect(borderRadius: BorderRadius.circular(20), child: buildPlantImage(currentImagePath, fit: BoxFit.cover, width: double.infinity))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded, size: 40, color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                                    const SizedBox(height: 8),
                                    Text('Tap to change photo', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _buildInputDecoration(context, 'Nickname', Icons.badge_rounded)),
                      const SizedBox(height: 14),
                      TextField(controller: speciesCtrl, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _buildInputDecoration(context, 'Species', Icons.grass_rounded)),
                      const SizedBox(height: 14),
                      TextField(controller: sciCtrl, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: _buildInputDecoration(context, 'Scientific Name (optional)', Icons.science_rounded)),
                      const SizedBox(height: 18),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Watering', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('$waterFreq days', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                      Slider(value: waterFreq.toDouble(), min: 1, max: 30, divisions: 29, activeColor: AppTheme.primaryGreen, inactiveColor: Colors.white.withValues(alpha: 0.1), onChanged: (v) => setModalState(() => waterFreq = v.round())),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Fertilizing', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('$fertFreq days', style: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                      Slider(value: fertFreq.toDouble(), min: 5, max: 90, divisions: 17, activeColor: AppTheme.accentAmber, inactiveColor: Colors.white.withValues(alpha: 0.1), onChanged: (v) => setModalState(() => fertFreq = v.round())),

                      // Health score override
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Current Health', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('$editedHealth%', style: TextStyle(color: _getHealthColor(editedHealth), fontWeight: FontWeight.w700, fontSize: 13)),
                      ]),
                      Slider(
                        value: editedHealth.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: _getHealthColor(editedHealth),
                        inactiveColor: Colors.white.withValues(alpha: 0.1),
                        onChanged: (v) => setModalState(() => editedHealth = v.round()),
                      ),
                      TextField(controller: notesCtrl, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 3, decoration: _buildInputDecoration(context, 'Notes', Icons.notes_rounded)),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : () async {
                            setModalState(() {
                              isSaving = true;
                            });

                            try {
                              String? finalImagePath;
                              if (pickedImageFile != null) {
                                try {
                                  final bytes = await pickedImageFile!.readAsBytes();
                                  final compressedBytes = await ImageService.compressBytes(bytes);
                                  finalImagePath = await ImageService.saveImageLocally(
                                    compressedBytes,
                                    'plant_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                  );
                                } catch (e) {
                                  debugPrint("⚠️ Edit plant image local compression failed: $e");
                                  if (kIsWeb) {
                                    try {
                                      final bytes = await pickedImageFile!.readAsBytes();
                                      final base64String = base64Encode(bytes);
                                      finalImagePath = 'data:image/jpeg;base64,$base64String';
                                    } catch (_) {
                                      finalImagePath = pickedImageFile!.path;
                                    }
                                  } else {
                                    finalImagePath = pickedImageFile!.path;
                                  }
                                }
                              } else {
                                finalImagePath = currentImagePath;
                              }

                              provider.updatePlant(
                                plant.id,
                                nickname: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                                species: speciesCtrl.text.trim().isNotEmpty ? speciesCtrl.text.trim() : null,
                                scientificName: sciCtrl.text.trim().isNotEmpty
                                    ? sciCtrl.text.trim()
                                    : (speciesCtrl.text.trim().isNotEmpty ? '${speciesCtrl.text.trim()} sp.' : null),
                                imagePath: finalImagePath,
                                wateringFrequencyDays: waterFreq,
                                fertilizingFrequencyDays: fertFreq,
                                notes: notesCtrl.text.trim(),
                                healthScore: editedHealth,
                              );
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                _showActionSnackBar(context, '✅ ${nameCtrl.text.trim()} updated!', AppTheme.primaryDarkGreen);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                _showActionSnackBar(context, '⚠️ Error updating plant: $e', AppTheme.dangerRed);
                              }
                            } finally {
                              setModalState(() {
                                isSaving = false;
                              });
                            }
                          },
                          icon: isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(isSaving ? 'Saving...' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Add Journal Dialog ───────────────────────────────────
  Future<void> _showAddJournalDialog(BuildContext context, GardenPlant plant, GardenProvider provider) async {
    final noteCtrl = TextEditingController();
    XFile? journalImage;
    String selectedMilestone = 'None';
    bool isSaving = false;

    final milestones = [
      'None',
      'First Bloom 🌸',
      'New Leaf 🌱',
      'Repotted 🪴',
      'Pruned ✂️',
      'Harvested 🍎',
      'New Growth 🌿',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: AppCard(
                borderRadius: 28,
                
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: Color(0xFFA78BFA), size: 22),
                        const SizedBox(width: 10),
                        Text('Journal Entry', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white70)),
                      ],
                    ),
                    Text('for ${plant.nickname}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 4,
                      decoration: _buildInputDecoration(context, 'How is your plant doing today?', Icons.edit_note_rounded),
                    ),
                    const SizedBox(height: 14),
                    // Optional photo — Camera or Gallery
                    GestureDetector(
                      onTap: () async {
                        final source = await showModalBottomSheet<ImageSource>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AppCard(
                            borderRadius: 24,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Add Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildImageSourceOption(context, Icons.camera_alt_rounded, 'Camera', ImageSource.camera),
                                    _buildImageSourceOption(context, Icons.photo_library_rounded, 'Gallery', ImageSource.gallery),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                        if (source != null) {
                          final picked = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 85);
                          if (picked != null) {
                            setModalState(() => journalImage = picked);
                          }
                        }
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          
                        ),
                        child: journalImage != null
                            ? Row(children: [
                                const SizedBox(width: 8),
                                ClipRRect(borderRadius: BorderRadius.circular(10), child: buildPlantImageFile(journalImage!, width: 44, height: 44, fit: BoxFit.cover)),
                                const SizedBox(width: 12),
                                Expanded(child: const Text('Photo attached', style: TextStyle(color: Colors.white70, fontSize: 13))),
                                IconButton(icon: Icon(Icons.close_rounded, size: 18, color: Colors.white.withValues(alpha: 0.4)), onPressed: () => setModalState(() => journalImage = null)),
                              ])
                            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.add_photo_alternate_rounded, size: 20, color: Colors.white.withValues(alpha: 0.3)),
                                const SizedBox(width: 8),
                                Text('Add a photo (optional)', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35))),
                              ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Milestone Achievement (optional)',
                      style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: milestones.map((m) {
                        final isSelected = selectedMilestone == m;
                        return ChoiceChip(
                          label: Text(m, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppTheme.accentAmber,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          checkmarkColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          onSelected: (selected) {
                            setModalState(() {
                              selectedMilestone = selected ? m : 'None';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : () async {
                          if (noteCtrl.text.trim().isEmpty) return;
                          
                          setModalState(() {
                            isSaving = true;
                          });

                          try {
                            String? imagePath;
                            if (journalImage != null) {
                              try {
                                final bytes = await journalImage!.readAsBytes();
                                final compressedBytes = await ImageService.compressBytes(bytes);
                                imagePath = await ImageService.saveImageLocally(
                                  compressedBytes,
                                  'journal_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                );
                              } catch (e) {
                                debugPrint("⚠️ Journal image local compression failed: $e");
                                if (kIsWeb) {
                                  try {
                                    final bytes = await journalImage!.readAsBytes();
                                    final base64String = base64Encode(bytes);
                                    imagePath = 'data:image/jpeg;base64,$base64String';
                                  } catch (_) {
                                    imagePath = journalImage!.path;
                                  }
                                } else {
                                  imagePath = journalImage!.path;
                                }
                              }
                            }

                            provider.addJournalEntry(
                              plant.id, 
                              noteCtrl.text.trim(), 
                              imagePath: imagePath,
                              milestone: selectedMilestone == 'None' ? null : selectedMilestone,
                            );
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              _showActionSnackBar(context, '📖 Journal entry added.', const Color(0xFF7C3AED));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showActionSnackBar(context, '⚠️ Error adding journal: $e', AppTheme.dangerRed);
                            }
                          } finally {
                            setModalState(() {
                              isSaving = false;
                            });
                          }
                        },
                        icon: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(isSaving ? 'Saving...' : 'Save Entry', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA78BFA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Delete Confirmation ──────────────────────────────────
  void _showDeleteConfirmation(BuildContext context, GardenPlant plant, GardenProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 24),
            const SizedBox(width: 10),
            const Text('Remove Plant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${plant.nickname}" from your garden? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletePlant(plant.id);
              Navigator.pop(context);
              _showActionSnackBar(context, '🗑️ ${plant.nickname} removed.', const Color(0xFF7F1D1D));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.yard_rounded, size: 100, color: AppTheme.primaryGreen.withValues(alpha: 0.4))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 2000.ms, curve: Curves.easeInOut),
            const SizedBox(height: 24),
            Text(
              'Your Garden Awaits',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
            ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              'Add your first plant and start tracking\nits growth, watering, and health.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5), height: 1.5),
            ).animate().fade(duration: 600.ms, delay: 400.ms),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddPlantSheet(
                    provider: Provider.of<GardenProvider>(context, listen: false),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Plant Your First Seed 🌱', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 6,
                ),
              ),
            ).animate().fade(duration: 600.ms, delay: 600.ms).scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 600.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ── Data Classes ───────────────────────────────────────────
class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatItem(this.icon, this.value, this.label, this.color);
}

class _FilterChip {
  final String label;
  final IconData? icon;
  const _FilterChip(this.label, this.icon);
}
