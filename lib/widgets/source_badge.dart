import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class SourceBadge extends StatelessWidget {
  final String source;

  const SourceBadge({
    super.key,
    required this.source,
  });

  IconData _getIcon() {
    final s = source.toLowerCase();
    if (s.contains('device')) {
      return Icons.phone_android_rounded;
    } else if (s.contains('verified') || s.contains('official')) {
      return Icons.verified_user_rounded;
    } else if (s.contains('override')) {
      return Icons.query_stats_rounded;
    } else {
      return Icons.science_rounded;
    }
  }

  Color _getColor() {
    final s = source.toLowerCase();
    if (s.contains('verified') || s.contains('official')) {
      return AppColors.primary;
    } else if (s.contains('device')) {
      return AppColors.warning;
    } else {
      return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            source.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
