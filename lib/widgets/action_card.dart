import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Expressive action card used on the Home screen for scan/upload CTAs.
/// Supports primary (gradient) and secondary (surface) styles.
class ActionCard extends StatefulWidget {
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
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;
    final textColor = isPrimary ? Colors.white : AppColors.onSurface;
    final subtextColor = isPrimary
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.onSurfaceMuted;

    final effectiveGradient = widget.gradient ??
        (isPrimary
            ? const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) async {
          await _pressController.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: effectiveGradient == null ? AppColors.surfaceElevated : null,
            gradient: effectiveGradient,
            borderRadius: BorderRadius.circular(20),
            border: !isPrimary
                ? Border.all(
                    color: AppColors.borderLight.withValues(alpha: 0.5),
                    width: 1,
                  )
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: (isPrimary
                        ? const Color(0xFF0D9488)
                        : Colors.black)
                    .withValues(alpha: isPrimary ? 0.28 : 0.14),
                blurRadius: isPrimary ? 16 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.surfaceHighlight,
                    border: Border.all(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppColors.borderLight.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: isPrimary ? Colors.white : AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 16),
                // Text column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.surfaceHighlight,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
