import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_colors.dart';
import '../models/garden_plant.dart';
import '../providers/garden_provider.dart';
import 'app_card.dart';
import 'plant_image.dart';
import 'health_painters.dart';

class PlantListCard extends StatelessWidget {
  final GardenPlant plant;
  final GardenProvider provider;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onAddJournal;
  final VoidCallback onDelete;

  const PlantListCard({
    super.key,
    required this.plant,
    required this.provider,
    required this.index,
    required this.onTap,
    required this.onAddJournal,
    required this.onDelete,
  });

  Color _getHealthColor(int score) {
    if (score >= 70) return AppTheme.primaryGreen;
    if (score >= 40) return AppTheme.accentAmber;
    return AppTheme.dangerRed;
  }

  String _formatDateShort(DateTime date) => DateFormat('MMM d').format(date);

  Widget _buildPlantImage(String imagePath, {double size = 80, double borderRadius = 16}) {
    if (imagePath.isNotEmpty && (kIsWeb || File(imagePath).existsSync())) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: buildPlantImage(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A2A), Color(0xFF0D2818)],
        ),
      ),
      child: Icon(Icons.yard_rounded, color: AppTheme.primaryGreen.withValues(alpha: 0.6), size: size * 0.45),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthColor(plant.computedHealthScore);

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        borderRadius: 22,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row: image + info
            Row(
              children: [
                _buildPlantImage(plant.imagePath),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.nickname,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        plant.species,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Added ${_formatDateShort(plant.dateAcquired)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                // Health Ring
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(52, 52),
                        painter: HealthRingPainter(progress: plant.computedHealthScore / 100, color: healthColor),
                      ),
                      Text(
                        '${plant.computedHealthScore}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: healthColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status pills
            Row(
              children: [
                if (plant.needsWatering)
                  _buildStatusPill('THIRSTY', AppTheme.dangerRed),
                if (plant.needsFertilizing)
                  _buildStatusPill('FERTILIZE', AppTheme.accentAmber),
                if (!plant.needsWatering && !plant.needsFertilizing && plant.computedHealthScore >= 70)
                  _buildStatusPill('HEALTHY', AppTheme.primaryGreen),
                if (plant.computedHealthScore < 40)
                  _buildStatusPill('CRITICAL', AppTheme.dangerRed),
                const Spacer(),
                // Days info
                Row(
                  children: [
                    Icon(Icons.water_drop_rounded, size: 13, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 3),
                    Text(
                      plant.needsWatering ? 'Overdue' : '${plant.daysUntilWatering}d',
                      style: TextStyle(
                        fontSize: 11,
                        color: plant.needsWatering ? AppTheme.dangerRed : Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.science_rounded, size: 13, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 3),
                    Text(
                      plant.needsFertilizing ? 'Overdue' : '${plant.daysUntilFertilizing}d',
                      style: TextStyle(
                        fontSize: 11,
                        color: plant.needsFertilizing ? AppTheme.accentAmber : Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 8),
            // Action row — scrollable horizontally to prevent overflow on small screens
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildActionButton(Icons.water_drop_rounded, 'Water', AppTheme.primaryGreen, () {
                    provider.waterPlant(plant.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${plant.nickname} has been watered.'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }),
                  _buildActionButton(Icons.science_rounded, 'Fertilize', AppTheme.accentAmber, () {
                    provider.fertilizePlant(plant.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${plant.nickname} has been fertilized.'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }),
                  _buildActionButton(
                    plant.notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                    plant.notificationsEnabled ? 'Alerts' : 'Muted',
                    plant.notificationsEnabled ? AppTheme.primaryGreen : Colors.white.withValues(alpha: 0.35),
                    () {
                      // Capture the NEW state (opposite of current) before toggling
                      final willEnable = !plant.notificationsEnabled;
                      provider.togglePlantNotifications(plant.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            willEnable
                                ? 'Reminders enabled for ${plant.nickname}'
                                : 'Reminders muted for ${plant.nickname}',
                          ),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(Icons.menu_book_rounded, 'Journal', const Color(0xFFA78BFA), onAddJournal),
                  _buildActionButton(Icons.delete_outline_rounded, 'Delete', Colors.white.withValues(alpha: 0.35), onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms, delay: (60 * index).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (60 * index).ms);
  }
}
