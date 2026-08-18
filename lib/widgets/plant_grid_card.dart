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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMiniAction(
      BuildContext context, IconData icon, Color color, VoidCallback onActionTap, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: onActionTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
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
        padding: EdgeInsets.zero,
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image Section ──────────────────────────────────────
            SizedBox(
              height: 115,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: plant.imagePath.isNotEmpty
                          ? buildPlantImage(plant.imagePath, fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1A3A2A),
                                    Color(0xFF0D2818),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.yard_rounded,
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.35),
                                  size: 44,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Bottom image gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Notification Bell Badge (Top Left)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: GestureDetector(
                      onTap: () {
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
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                          border: Border.all(
                            color: plant.notificationsEnabled
                                ? AppTheme.primaryGreen.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.18),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          plant.notificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          size: 15,
                          color: plant.notificationsEnabled
                              ? AppTheme.primaryGreen
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  // Health score badge (Top Right)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: healthColor.withValues(alpha: 0.6), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_rounded,
                              size: 8, color: healthColor),
                          const SizedBox(width: 3),
                          Text(
                            '${plant.computedHealthScore}%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: healthColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Info Section ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.nickname,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      plant.species,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Status pills
                    if (plant.needsWatering || plant.needsFertilizing)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (plant.needsWatering)
                            _buildStatusPill('💧 THIRSTY', AppColors.info),
                          if (plant.needsFertilizing)
                            _buildStatusPill('🧪 FEED', AppTheme.accentAmber),
                        ],
                      )
                    else
                      _buildStatusPill('✓ HEALTHY', AppTheme.primaryGreen),
                    const SizedBox(height: 7),
                    // Mini action row
                    Row(
                      children: [
                        _buildMiniAction(
                          context,
                          Icons.water_drop_rounded,
                          AppTheme.primaryGreen,
                          () {
                            provider.waterPlant(plant.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '💧 ${plant.nickname} watered!'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          'Water',
                        ),
                        _buildMiniAction(
                          context,
                          Icons.science_rounded,
                          AppTheme.accentAmber,
                          () {
                            provider.fertilizePlant(plant.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '🧪 ${plant.nickname} fertilized!'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          'Feed',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fade(duration: 380.ms, delay: (70 * index).ms)
        .scale(
          begin: const Offset(0.90, 0.90),
          end: const Offset(1, 1),
          duration: 380.ms,
          delay: (70 * index).ms,
          curve: Curves.easeOutCubic,
        );
  }
}
