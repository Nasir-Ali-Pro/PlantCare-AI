import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_colors.dart';
import '../models/garden_plant.dart';
import '../providers/garden_provider.dart';
import 'app_card.dart';
import 'plant_image.dart';

class PlantGridCard extends StatelessWidget {
  final GardenPlant plant;
  final GardenProvider provider;
  final int index;
  final VoidCallback onTap;

  const PlantGridCard({
    super.key,
    required this.plant,
    required this.provider,
    required this.index,
    required this.onTap,
  });

  Color _getHealthColor(int score) {
    if (score >= 70) return AppTheme.primaryGreen;
    if (score >= 40) return AppTheme.accentAmber;
    return AppTheme.dangerRed;
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMiniAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthColor(plant.computedHealthScore);

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            SizedBox(
              height: 110,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      // buildPlantImage handles missing/bad paths via its errorBuilder —
                      // no blocking File.existsSync() needed on the UI thread.
                      child: plant.imagePath.isNotEmpty
                          ? buildPlantImage(plant.imagePath, fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF1A3A2A), Color(0xFF0D2818)],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.yard_rounded,
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                                  size: 42,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Notification Bell Badge (Top Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {
                        // Capture the NEW state before toggling
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
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.6),
                          border: Border.all(
                            color: plant.notificationsEnabled
                                ? AppTheme.primaryGreen.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          plant.notificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          size: 16,
                          color: plant.notificationsEnabled
                              ? AppTheme.primaryGreen
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  // Health badge (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.6),
                        border: Border.all(color: healthColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${plant.computedHealthScore}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: healthColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.nickname,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.species,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Status
                    if (plant.needsWatering || plant.needsFertilizing)
                      Wrap(
                        spacing: 4,
                        children: [
                          if (plant.needsWatering) _buildStatusPill('💧', AppTheme.dangerRed),
                          if (plant.needsFertilizing) _buildStatusPill('🧪', AppTheme.accentAmber),
                        ],
                      )
                    else
                      _buildStatusPill('HEALTHY', AppTheme.primaryGreen),
                    const SizedBox(height: 6),
                    // Mini actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMiniAction(Icons.water_drop_rounded, AppTheme.primaryGreen, () {
                          provider.waterPlant(plant.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${plant.nickname} has been watered.'),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }),
                        _buildMiniAction(Icons.science_rounded, AppTheme.accentAmber, () {
                          provider.fertilizePlant(plant.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${plant.nickname} has been fertilized.'),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms, delay: (80 * index).ms).scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), duration: 400.ms, delay: (80 * index).ms);
  }
}
