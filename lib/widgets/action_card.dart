import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final bool isPrimary;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = isPrimary ? AppColors.primary : AppColors.surfaceElevated;
    final textThemeColor = isPrimary ? Colors.white : AppColors.onSurface;
    final subtextColor = isPrimary ? Colors.white.withValues(alpha: 0.75) : AppColors.onSurfaceMuted;

    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? baseColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: !isPrimary
            ? Border.all(color: AppColors.borderLight.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: (isPrimary ? AppColors.primary : Colors.black).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.surfaceHighlight.withValues(alpha: 0.5),
                    border: isPrimary
                        ? Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5)
                        : Border.all(color: AppColors.borderLight.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isPrimary ? Colors.white : AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textThemeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: subtextColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
