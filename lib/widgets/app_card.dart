import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A versatile card widget with solid, elevated, or glass-morphism styles.
class AppCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final Color? borderColor;
  final bool elevated;
  final bool glassEffect;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.borderColor,
    this.elevated = false,
    this.glassEffect = false,
    this.shadows,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = glassEffect
        ? AppColors.surfaceGlass
        : (color ?? (elevated ? AppColors.surfaceElevated : AppColors.surface));

    final effectiveShadows = shadows ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.22 : 0.12),
            blurRadius: elevated ? 20 : 10,
            offset: Offset(0, elevated ? 6 : 3),
          ),
        ];

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.border.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 0.5),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (glassEffect) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: card,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}
