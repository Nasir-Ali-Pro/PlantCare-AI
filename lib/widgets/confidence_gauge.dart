import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ConfidenceGauge extends StatefulWidget {
  final double confidence;
  final double size;

  const ConfidenceGauge({
    super.key,
    required this.confidence,
    this.size = 120,
  });

  @override
  State<ConfidenceGauge> createState() => _ConfidenceGaugeState();
}

class _ConfidenceGaugeState extends State<ConfidenceGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ConfidenceGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.confidence != widget.confidence) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(double value) {
    if (value >= 0.85) {
      return AppColors.primary;
    } else if (value >= 0.65) {
      return AppColors.warning;
    } else {
      return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double score = widget.confidence.clamp(0.0, 1.0);
    final Color color = _getColor(score);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double animatedValue = _animation.value * score;
        
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular background track
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: const CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  color: AppColors.border,
                ),
              ),
              // Circular gauge progress
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: animatedValue,
                  strokeWidth: 8,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Inner Text Label
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(animatedValue * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'Confidence',
                    style: TextStyle(
                      fontSize: widget.size * 0.08,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
