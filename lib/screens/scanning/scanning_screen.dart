import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/diagnosis_provider.dart';
import '../../providers/garden_provider.dart';
import '../../widgets/animated_scan_overlay.dart';
import '../../widgets/app_card.dart';
import '../../widgets/plant_image.dart';
import '../result/result_screen.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  
  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  void _setupListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DiagnosisProvider>(context, listen: false);
      
      provider.addListener(() {
        if (!mounted) return;
        
        if (provider.state == DiagnosisState.success && provider.currentReport != null) {
          final report = provider.currentReport!;
          final isDiseased = report.diseaseName.toLowerCase() != 'healthy' && 
                             report.diseaseName.toLowerCase() != 'unknown' && 
                             report.diseaseName.toLowerCase() != 'identified species';
          
          Provider.of<GardenProvider>(context, listen: false).incrementScanCount(isDiseased);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(report: report),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final image = provider.selectedImage;
        final status = provider.statusMessage;
        final error = provider.errorMessage;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back Action
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            provider.reset();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurfaceMuted),
                        ),
                        const Text(
                          'Analyzing...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.onSurfaceMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Image preview box
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (image != null)
                                  buildPlantImageFile(
                                    image,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Container(
                                    color: AppColors.surface,
                                    child: const Center(
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    ),
                                  ),
                                
                                Container(
                                  color: Colors.black.withValues(alpha: 0.15),
                                ),

                                if (state == DiagnosisState.analyzingLocal || state == DiagnosisState.verifyingCloud)
                                  const AnimatedScanOverlay(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Progress / Status
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (error != null) ...[
                          (() {
                            final bool isNotPlantError = error.toLowerCase().contains("not a plant") || error.contains("NOT_A_PLANT") || error.toLowerCase().contains("does not appear to be a plant");
                            if (isNotPlantError) {
                              return AppCard(
                                borderRadius: 24,
                                color: AppColors.surfaceElevated,
                                borderColor: AppColors.warning.withValues(alpha: 0.3),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.park_outlined, color: AppColors.warning, size: 42),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Not a Plant Leaf 🍃',
                                      style: TextStyle(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "The uploaded picture is not a plant, and I cannot assist you. PlantCare AI is dedicated specifically to plant health diagnostics and botanical care.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.onSurface,
                                        fontSize: 14.5,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fade(duration: 300.ms).slideY(begin: 0.05);
                            }
                            return AppCard(
                              borderRadius: 20,
                              color: AppColors.surfaceElevated,
                              borderColor: AppColors.border,
                              child: Column(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Analysis failed',
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    constraints: const BoxConstraints(maxHeight: 120),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Text(
                                        error,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.onSurfaceMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fade(duration: 300.ms);
                          })(),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              provider.reset();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.replay_circle_filled_rounded),
                            label: const Text('Try Scan Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ] else ...[
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                          
                          const SizedBox(height: 24),
                          
                          Text(
                            status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: AppColors.onSurface,
                            ),
                          ).animate(key: ValueKey(status))
                           .fade(duration: 300.ms)
                           .slideY(begin: 0.05, duration: 300.ms),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            _getSubtextForState(state),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.onSurfaceMuted,
                              fontSize: 14,
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          TextButton.icon(
                            onPressed: () {
                              provider.reset();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.cancel_rounded, color: AppColors.onSurfaceFaint),
                            label: const Text(
                              'Cancel Diagnosis',
                              style: TextStyle(color: AppColors.onSurfaceFaint, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getSubtextForState(DiagnosisState state) {
    switch (state) {
      case DiagnosisState.loadingImage:
        return 'Identifying plant...';
      case DiagnosisState.analyzingLocal:
        return 'Checking health...';
      case DiagnosisState.verifyingCloud:
        return 'Checking database and generating pathological report...';
      case DiagnosisState.success:
        return 'Diagnosis compiled!';
      case DiagnosisState.error:
        return 'Analysis failed';
      case DiagnosisState.idle:
        return 'Awaiting input...';
    }
  }
}
