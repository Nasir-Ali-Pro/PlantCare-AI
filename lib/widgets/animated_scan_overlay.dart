import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AnimatedScanOverlay extends StatefulWidget {
  const AnimatedScanOverlay({super.key});

  @override
  State<AnimatedScanOverlay> createState() => _AnimatedScanOverlayState();
}

class _AnimatedScanOverlayState extends State<AnimatedScanOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: _animation.value),
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _animation.value * 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
