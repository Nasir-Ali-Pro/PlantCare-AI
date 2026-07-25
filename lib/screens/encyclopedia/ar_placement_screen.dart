import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/garden_provider.dart';
import '../../widgets/app_card.dart';

class ArPlacementScreen extends StatefulWidget {
  final String plantName;
  final String category;

  const ArPlacementScreen({
    super.key,
    required this.plantName,
    required this.category,
  });

  @override
  State<ArPlacementScreen> createState() => _ArPlacementScreenState();
}

class _ArPlacementScreenState extends State<ArPlacementScreen> {
  double _scale = 1.0;
  double _rotation = 0.0;
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  
  bool _isAnchored = false;

  @override
  Widget build(BuildContext context) {
    IconData plantIcon = Icons.eco_rounded;
    Color plantColor = AppColors.primary;

    if (widget.category.toLowerCase().contains('vegetable')) {
      plantIcon = Icons.grass_rounded;
      plantColor = Colors.lightGreenAccent;
    } else if (widget.category.toLowerCase().contains('fruit tree')) {
      plantIcon = Icons.park_rounded;
      plantColor = Colors.tealAccent;
    } else if (widget.category.toLowerCase().contains('fruit')) {
      plantIcon = Icons.local_florist_rounded;
      plantColor = Colors.pinkAccent;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Mock Camera Feed Background
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: GridPaper(
                  color: Colors.white10,
                  interval: 100,
                  subdivisions: 4,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_rounded, color: Colors.white12, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          'AR CAMERA INITIATED',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          'Move phone slowly to detect floor anchors...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.1),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floor Anchoring Circle Overlay
            if (!_isAnchored)
              Center(
                child: Container(
                  width: 180,
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                    borderRadius: const BorderRadius.all(Radius.elliptical(180, 90)),
                    color: AppColors.primary.withValues(alpha: 0.04),
                  ),
                  child: const Center(
                    child: Text(
                      'TAP TO PLACE PLANT',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1))
                    .fade(duration: 1.seconds, begin: 0.5, end: 0.9),
              ),

            // Interactive 3D Plant Model Simulator
            if (_isAnchored)
              Positioned(
                left: (MediaQuery.of(context).size.width / 2 - 60) + _xOffset,
                top: (MediaQuery.of(context).size.height / 2 - 120) + _yOffset,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _xOffset += details.delta.dx;
                      _yOffset += details.delta.dy;
                    });
                  },
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..scale(_scale)
                      ..rotateY(_rotation),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: plantColor.withValues(alpha: 0.12),
                            border: Border.all(color: plantColor, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: plantColor.withValues(alpha: 0.3),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: Icon(
                            plantIcon,
                            color: plantColor,
                            size: 70,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(duration: 900.ms, begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05))
                            .then()
                            .shake(duration: 300.ms, hz: 1),
                        const SizedBox(height: 12),
                        Container(
                          width: 100,
                          height: 25,
                          decoration: BoxDecoration(
                            border: Border.all(color: plantColor.withValues(alpha: 0.7), width: 1.5),
                            borderRadius: const BorderRadius.all(Radius.elliptical(100, 25)),
                            color: plantColor.withValues(alpha: 0.06),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Tap area on floor to anchor
            if (!_isAnchored)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAnchored = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Anchored ${widget.plantName} to floor surface.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),

            // Header Bar Actions
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  ),
                  const Text(
                    'AR PLANT PLACEMENT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isAnchored = false;
                        _scale = 1.0;
                        _rotation = 0.0;
                        _xOffset = 0.0;
                        _yOffset = 0.0;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Bottom Control Panel
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isAnchored) ...[
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      borderRadius: 20,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.photo_size_select_large_rounded, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              const Text('Scale', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              Expanded(
                                child: Slider(
                                  value: _scale,
                                  min: 0.5,
                                  max: 2.5,
                                  activeColor: AppColors.primary,
                                  inactiveColor: Colors.white12,
                                  onChanged: (val) {
                                    setState(() {
                                      _scale = val;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.rotate_right_rounded, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              const Text('Rotate', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              Expanded(
                                child: Slider(
                                  value: _rotation,
                                  min: -3.14,
                                  max: 3.14,
                                  activeColor: AppColors.warning,
                                  inactiveColor: Colors.white12,
                                  onChanged: (val) {
                                    setState(() {
                                      _rotation = val;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      if (_isAnchored)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Provider.of<GardenProvider>(context, listen: false).addPlant(
                                nickname: 'AR ${widget.plantName}',
                                species: widget.plantName,
                                scientificName: '${widget.plantName} ar-placed',
                                imagePath: '',
                                wateringFrequencyDays: 7,
                                fertilizingFrequencyDays: 30,
                                notes: 'Placed and spacing verified via AR Sandbox visualizer.',
                              );
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added AR ${widget.plantName} directly to your Garden.'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Add to Garden', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      else
                        const Expanded(
                          child: AppCard(
                            padding: EdgeInsets.all(16),
                            borderRadius: 16,
                            child: Center(
                              child: Text(
                                'Identify flat surface floor and tap to anchor 3D plant.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Immersive spacing tags
            if (_isAnchored) ...[
              Positioned(
                top: 100,
                left: 24,
                child: const AppCard(
                  padding: EdgeInsets.all(10),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14),
                      SizedBox(width: 6),
                      Text('SAFE WALL DISTANCE: 2.5 FT', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 100,
                right: 24,
                child: const AppCard(
                  padding: EdgeInsets.all(10),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      Icon(Icons.wb_sunny_rounded, color: AppColors.warning, size: 14),
                      SizedBox(width: 6),
                      Text('LIGHT INTENSITY: IDEAL', style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
