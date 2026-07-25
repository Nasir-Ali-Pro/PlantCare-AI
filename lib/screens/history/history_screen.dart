import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/diagnosis_report.dart';
import '../../providers/diagnosis_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/plant_image.dart';
import '../result/result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

// We rename the state class or use the standard one
class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String _selectedSpecies = 'All';

  List<String> _getAvailableSpecies(List<DiagnosisReport> history) {
    final speciesSet = {'All'};
    for (var item in history) {
      if (item.plantName.isNotEmpty) {
        speciesSet.add(item.plantName);
      }
    }
    return speciesSet.toList();
  }

  void _clearAllHistory(BuildContext context, DiagnosisProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Scan History?', style: TextStyle(color: AppColors.onSurface)),
        content: const Text(
          'This will permanently delete all saved diagnosis reports. This action cannot be undone.',
          style: TextStyle(color: AppColors.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceMuted)),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(context);
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (context, provider, child) {
        final rawHistory = provider.history;
        final speciesFilters = _getAvailableSpecies(rawHistory);

        final history = rawHistory.where((item) {
          final matchesSearch = item.diseaseName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.plantName.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesSpecies = _selectedSpecies == 'All' || item.plantName == _selectedSpecies;
          return matchesSearch && matchesSpecies;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurfaceMuted),
            ),
            title: const Text(
              'Scan History',
              style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              if (rawHistory.isNotEmpty)
                IconButton(
                  onPressed: () => _clearAllHistory(context, provider),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 28, color: AppColors.danger),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (rawHistory.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Column(
                      children: [
                        // Search TextField
                        TextField(
                          style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by plant or disease name...',
                            hintStyle: const TextStyle(color: AppColors.onSurfaceFaint, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Horizontal Species Filter Chips
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: speciesFilters.length,
                            itemBuilder: (context, index) {
                              final species = speciesFilters[index];
                              final isSelected = _selectedSpecies == species;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(
                                    species,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.onSurfaceMuted,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: AppColors.surface,
                                  shadowColor: Colors.transparent,
                                  surfaceTintColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                    side: BorderSide(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                      width: 1.0,
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSpecies = species;
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
                ],

                // History List View
                Expanded(
                  child: history.isEmpty
                      ? _buildEmptyState(rawHistory.isEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final report = history[index];
                            return _buildHistoryItem(context, report, provider)
                                .animate()
                                .fade(delay: (index * 40).ms, duration: 300.ms)
                                .slideY(begin: 0.05);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, DiagnosisReport report, DiagnosisProvider provider) {
    final dateString = DateFormat('MMM dd, yyyy • hh:mm a').format(report.dateTime);
    final isDevice = report.source.toLowerCase().contains('device');

    return Dismissible(
      key: Key(report.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 1.2),
        ),
        child: const Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 28),
      ),
      onDismissed: (direction) {
        provider.deleteHistoryItem(report.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted report for ${report.diseaseName}'),
            backgroundColor: AppColors.surfaceElevated,
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.primary,
              onPressed: () {},
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: AppCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(report: report, fromHistory: true),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: buildPlantImage(
                      report.imagePath,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.diseaseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.plantName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                dateString,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceFaint,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              report.source.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: isDevice ? AppColors.warning : AppColors.primary,
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
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool absoluteEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
              ),
              child: Icon(
                absoluteEmpty ? Icons.history_edu_rounded : Icons.find_in_page_rounded,
                size: 60,
                color: AppColors.onSurfaceFaint,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              absoluteEmpty ? 'No scans yet' : 'No matching results found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              absoluteEmpty
                  ? 'Your scan history will appear here.'
                  : 'Try typing a different search query or select another species filter.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
