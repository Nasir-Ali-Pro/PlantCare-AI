import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../models/diagnosis_report.dart';
import '../../providers/diagnosis_provider.dart';
import '../../widgets/confidence_gauge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/source_badge.dart';
import '../../widgets/plant_image.dart';
import '../forum/forum_screen.dart';
import '../../models/shop_product.dart';
import 'dart:convert';
import '../../providers/chat_provider.dart';
import '../../providers/garden_provider.dart';
import '../../providers/shop_provider.dart';
import '../main_navigation_shell.dart';
import '../../services/review_service.dart';

class ResultScreen extends StatelessWidget {
  final DiagnosisReport report;
  final bool fromHistory;

  const ResultScreen({
    super.key,
    required this.report,
    this.fromHistory = false,
  });

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return AppColors.success;
      case 'moderate':
        return AppColors.warning;
      case 'high':
        return AppColors.warning;
      case 'critical':
      default:
        return AppColors.danger;
    }
  }

  void _shareReport(BuildContext context) {
    final String shareText = 
        "PlantCare AI Diagnosis Report\n"
        "-------------------------------------\n"
        "Plant: ${report.plantName}\n"
        "Diagnosis: ${report.diseaseName}\n"
        "Severity: ${report.severity}\n"
        "Source: ${report.source}\n\n"
        "Description:\n${report.description}\n\n"
        "Key Symptoms:\n${report.symptoms.map((s) => '- $s').join('\n')}\n\n"
        "Treatment Plan:\n${report.treatment.map((t) => '- $t').join('\n')}\n\n"
        "Diagnosed with PlantCare AI app.";
    
    Share.share(shareText, subject: 'Plant Diagnosis: ${report.diseaseName}');
  }

  @override
  Widget build(BuildContext context) {
    final bool isIdentify = report.diseaseName == "Identified Species";
    
    // Trigger review prompt after a successful, non-history diagnosis view.
    if (!fromHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
        ReviewService.maybeRequestReview(scanCount: gardenProvider.scanCount);
      });
    }

    final severityColor = isIdentify
        ? (report.severity.toLowerCase() == 'easy' 
            ? AppColors.success 
            : (report.severity.toLowerCase() == 'hard' 
                ? AppColors.danger 
                : AppColors.warning))
        : _getSeverityColor(report.severity);

    Map<String, dynamic> idData = {};
    if (isIdentify && report.localCritiqueExplanation != null) {
      try {
        idData = json.decode(report.localCritiqueExplanation!);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header / Back & Share buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (fromHistory) {
                        Navigator.pop(context);
                      } else {
                        final provider = Provider.of<DiagnosisProvider>(context, listen: false);
                        provider.reset();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurfaceMuted),
                  ),
                  Text(
                    isIdentify ? 'Species Identification' : 'Diagnosis Results',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shareReport(context),
                    icon: const Icon(Icons.ios_share_rounded, color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
            ),

            // Main scrollable list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Display with Badge overlays
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            buildPlantImage(
                              report.imagePath,
                              fit: BoxFit.cover,
                            ),
                            // Floating Source Badge
                            Positioned(
                              top: 16,
                              left: 16,
                              child: SourceBadge(source: report.source),
                            ),
                            // Floating Severity Badge
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: severityColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: severityColor.withValues(alpha: 0.4), width: 1),
                                ),
                                child: Text(
                                  isIdentify ? "DIFFICULTY: ${report.severity.toUpperCase()}" : report.severity.toUpperCase(),
                                  style: TextStyle(
                                    color: severityColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(duration: 300.ms),

                    const SizedBox(height: 24),

                    // Title & Confidence row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIdentify 
                                    ? (idData['family'] ?? 'Botanical Family') 
                                    : report.plantName,
                                style: const TextStyle(
                                  color: AppColors.onSurfaceMuted,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isIdentify
                                    ? (idData['commonName'] ?? report.plantName)
                                    : report.diseaseName,
                                style: const TextStyle(
                                  fontFamily: 'DMSerifDisplay',
                                  fontSize: 26,
                                  height: 1.2,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              if (isIdentify && idData['scientificName'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  idData['scientificName'],
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ConfidenceGauge(confidence: report.confidence, size: 90)
                            .animate().scale(duration: 300.ms, curve: Curves.easeOut),
                      ],
                    ).animate().fade(delay: 100.ms, duration: 300.ms),

                    if (isIdentify) ...[
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _buildCareCard(
                            title: "Difficulty",
                            value: idData['careDifficulty'] ?? "Medium",
                            icon: Icons.speed_rounded,
                            iconColor: AppColors.primary,
                          ),
                          _buildCareCard(
                            title: "Light",
                            value: idData['lightRequirement'] ?? "Indirect Light",
                            icon: Icons.wb_sunny_rounded,
                            iconColor: AppColors.warning,
                          ),
                          _buildCareCard(
                            title: "Watering",
                            value: idData['wateringFrequencyDays'] != null
                                ? "Every ${idData['wateringFrequencyDays']} days"
                                : "Every 7 days",
                            icon: Icons.water_drop_rounded,
                            iconColor: AppColors.accentLight,
                          ),
                          _buildCareCard(
                            title: "Pet Toxicity",
                            value: idData['toxicity'] ?? "Safe",
                            icon: Icons.pets_rounded,
                            iconColor: AppColors.danger,
                          ),
                        ],
                      ).animate().fade(delay: 150.ms, duration: 300.ms),

                      const SizedBox(height: 20),
                      AppCard(
                        borderRadius: 16,
                        color: AppColors.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About this plant',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              idData['description'] ?? report.description,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(delay: 200.ms, duration: 300.ms),

                      const SizedBox(height: 20),
                      _buildRecommendedProductsSection(context, idData['commonName'] ?? report.plantName)
                          .animate().fade(delay: 250.ms, duration: 300.ms),

                      const SizedBox(height: 24),
                      
                      // Add to My Garden button
                      ElevatedButton.icon(
                        onPressed: () => _showAddPlantBottomSheet(context, idData),
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Add to My Garden'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ).animate().fade(delay: 300.ms, duration: 300.ms),
                    ] else ...[
                      const SizedBox(height: 20),
                      // Critique / Override Alert Panel
                      if (report.localCritiqueExplanation != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: report.source.toLowerCase().contains('override') 
                                ? AppColors.danger.withValues(alpha: 0.08)
                                : AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: report.source.toLowerCase().contains('override') 
                                  ? AppColors.danger.withValues(alpha: 0.3)
                                  : AppColors.success.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    report.source.toLowerCase().contains('override') 
                                        ? Icons.gpp_maybe_rounded 
                                        : Icons.verified_rounded,
                                    color: report.source.toLowerCase().contains('override') 
                                        ? AppColors.danger 
                                        : AppColors.success,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    report.source.toLowerCase().contains('override') 
                                        ? 'AI Analysis' 
                                        : 'Verified Analysis',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: report.source.toLowerCase().contains('override') 
                                          ? AppColors.danger 
                                          : AppColors.success,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report.localCritiqueExplanation!,
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade(delay: 150.ms, duration: 300.ms),
                        const SizedBox(height: 20),
                      ],

                      // Description panel
                      AppCard(
                        borderRadius: 16,
                        color: AppColors.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About this condition',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              report.description,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(delay: 200.ms, duration: 300.ms),

                      const SizedBox(height: 16),

                      // Expandable Panels for Details
                      _buildExpandableTile(
                        context: context,
                        title: 'Identified Symptoms',
                        icon: Icons.search_off_rounded,
                        color: severityColor,
                        items: report.symptoms,
                      ).animate().fade(delay: 250.ms, duration: 300.ms),
                      
                      const SizedBox(height: 12),

                      _buildExpandableTile(
                        context: context,
                        title: 'Immediate Actions & Treatment',
                        icon: Icons.medical_services_rounded,
                        color: AppColors.primary,
                        items: report.treatment,
                      ).animate().fade(delay: 250.ms, duration: 300.ms),

                      const SizedBox(height: 12),

                      _buildExpandableTile(
                        context: context,
                        title: 'Long-Term Prevention',
                        icon: Icons.shield_rounded,
                        color: AppColors.warning,
                        items: report.prevention,
                      ).animate().fade(delay: 250.ms, duration: 300.ms),

                      const SizedBox(height: 20),

                      _buildRecommendedProductsSection(context, report.diseaseName)
                          .animate().fade(delay: 280.ms, duration: 300.ms),

                      const SizedBox(height: 24),

                      // Chat with AI Doctor button
                      ElevatedButton.icon(
                        onPressed: () {
                          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                          chatProvider.startDoctorConsultation(report);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainNavigationShell(initialIndex: 2),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.medical_services_rounded),
                        label: const Text('Chat with AI Doctor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ).animate().fade(delay: 290.ms, duration: 300.ms),

                      const SizedBox(height: 12),

                      // Ask Community button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForumScreen(
                                autoAttachDiagnosisName: report.diseaseName,
                                autoAttachImagePath: report.imagePath,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.forum_rounded, color: AppColors.primary),
                        label: const Text(
                          'Ask Community for Second Opinion',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ).animate().fade(delay: 300.ms, duration: 300.ms),
                    ],

                    const SizedBox(height: 12),

                    // Capture Again button
                    if (!fromHistory) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          final provider = Provider.of<DiagnosisProvider>(context, listen: false);
                          provider.reset();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.camera_enhance_rounded),
                        label: const Text('Scan another plant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ).animate().fade(delay: 310.ms, duration: 300.ms),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.onSurfaceMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showAddPlantBottomSheet(BuildContext context, Map<String, dynamic> idData) {
    final nicknameController = TextEditingController(text: idData['commonName'] ?? report.plantName);
    final notesController = TextEditingController();
    
    // Care values
    int wateringFrequency = idData['wateringFrequencyDays'] ?? 7;
    int fertilizingFrequency = idData['fertilizingFrequencyDays'] ?? 30;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Add Plant to Garden',
                      style: TextStyle(
                        fontFamily: 'DMSerifDisplay',
                        fontSize: 24,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Nickname Input
                    TextField(
                      controller: nicknameController,
                      style: const TextStyle(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Plant Nickname',
                        labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Species details read-only
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Species', style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                idData['commonName'] ?? report.plantName,
                                style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Scientific Name', style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                idData['scientificName'] ?? 'Unknown',
                                style: const TextStyle(color: AppColors.onSurface, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Watering Slider
                    Text(
                      'Watering Frequency: Every $wateringFrequency days',
                      style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Slider(
                      value: wateringFrequency.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          wateringFrequency = val.round();
                        });
                      },
                    ),
                    
                    // Fertilizing Slider
                    Text(
                      'Fertilizing Frequency: Every $fertilizingFrequency days',
                      style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Slider(
                      value: fertilizingFrequency.toDouble(),
                      min: 1,
                      max: 90,
                      divisions: 89,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        setState(() {
                          fertilizingFrequency = val.round();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Notes Input
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: AppColors.onSurface),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Care Notes',
                        labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Submit button
                    ElevatedButton(
                      onPressed: () async {
                        final nickname = nicknameController.text.trim();
                        final parentMessenger = ScaffoldMessenger.of(context);
                        if (nickname.isEmpty) {
                          parentMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a nickname!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        
                        final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
                        await gardenProvider.addPlant(
                          nickname: nickname,
                          species: idData['commonName'] ?? report.plantName,
                          scientificName: idData['scientificName'] ?? 'Unknown Scientific Name',
                          imagePath: report.imagePath,
                          wateringFrequencyDays: wateringFrequency,
                          fertilizingFrequencyDays: fertilizingFrequency,
                          notes: notesController.text.trim(),
                        );
                        
                        if (context.mounted) {
                          Navigator.pop(context); // Close bottom sheet
                          parentMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Added $nickname to garden! 🌱'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add Plant', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpandableTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.onSurface,
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Returns the most relevant shop products for a given diagnosis.
  /// Uses tiered keyword matching against disease/pest/care categories.
  List<ShopProduct> _getRecommendedProducts(String diseaseName) {
    final name = diseaseName.toLowerCase();
    final allProds = ShopProduct.defaultProducts;

    // ── Fungal / Mold / Mildew ─────────────────────────────
    if (name.contains('fungal') || name.contains('mildew') ||
        name.contains('rust') || name.contains('blight') ||
        name.contains('spot') || name.contains('scab') ||
        name.contains('mold') || name.contains('anthracnose') ||
        name.contains('leaf curl') || name.contains('downy')) {
      return allProds
          .where((p) =>
              p.id == 'prod_neem_oil' ||
              p.id == 'prod_copper_fungicide' ||
              p.id == 'prod_systemic_pest')
          .toList();
    }

    // ── Root Rot / Stem Rot / Wilt ─────────────────────────
    if (name.contains('rot') || name.contains('damping') ||
        name.contains('wilt') || name.contains('crown rot') ||
        name.contains('pythium') || name.contains('phytophthora')) {
      return allProds
          .where((p) =>
              p.id == 'prod_copper_fungicide' ||
              p.id == 'prod_moisture_meter' ||
              p.id == 'prod_perlite')
          .toList();
    }

    // ── Insect Pests ───────────────────────────────────────
    if (name.contains('pest') || name.contains('aphid') ||
        name.contains('mite') || name.contains('scale') ||
        name.contains('bug') || name.contains('thrip') ||
        name.contains('insect') || name.contains('caterpillar') ||
        name.contains('gnat') || name.contains('whitefly') ||
        name.contains('mealybug') || name.contains('leafhopper')) {
      return allProds
          .where((p) =>
              p.id == 'prod_neem_oil' ||
              p.id == 'prod_systemic_pest' ||
              p.id == 'prod_insect_soap')
          .toList();
    }

    // ── Nutrient Deficiency ────────────────────────────────
    if (name.contains('nutrient') || name.contains('deficiency') ||
        name.contains('chlorosis') || name.contains('nitrogen') ||
        name.contains('yellowing') || name.contains('pale')) {
      return allProds
          .where((p) =>
              p.id == 'prod_miracle_gro' ||
              p.id == 'prod_osmocote' ||
              p.id == 'prod_jobes_spikes')
          .toList();
    }

    // ── Watering / Overwatering ────────────────────────────
    if (name.contains('overwatering') || name.contains('dehydration') ||
        name.contains('wilting') || name.contains('drought')) {
      return allProds
          .where((p) =>
              p.id == 'prod_moisture_meter' ||
              p.id == 'prod_self_watering_pots' ||
              p.id == 'prod_watering_can')
          .toList();
    }

    // ── Healthy Plant — General care recommendations ────────
    if (name == 'healthy') {
      return allProds
          .where((p) =>
              p.id == 'prod_moisture_meter' ||
              p.id == 'prod_miracle_gro' ||
              p.id == 'prod_superthrive')
          .toList();
    }

    // ── Species Identification — propagation and growth ────
    if (name.contains('identified species') || name.contains('monstera') ||
        name.contains('pothos') || name.contains('philodendron') ||
        name.contains('ficus') || name.contains('succulent')) {
      return allProds
          .where((p) =>
              p.id == 'prod_propagation_station' ||
              p.id == 'prod_rooting_powder' ||
              p.id == 'prod_soil_mix')
          .toList();
    }

    // ── General fallback ───────────────────────────────────
    return allProds
        .where((p) =>
            p.id == 'prod_neem_oil' ||
            p.id == 'prod_moisture_meter')
        .toList();
  }

  Widget _buildRecommendedProductsSection(BuildContext context, String diseaseName) {
    final recommended = _getRecommendedProducts(diseaseName);
    if (recommended.isEmpty) return const SizedBox.shrink();

    return Consumer<ShopProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: AppColors.accent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECOMMENDED SUPPLIES',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Products selected for your diagnosis',
                          style: TextStyle(
                            color: AppColors.onSurface.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Product Cards ───────────────────────────────────
            ...recommended.map((product) {
              final isFav = provider.isFavorite(product.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 16,
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      // Product Mini Image
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: buildPlantImage(
                            product.imageUrl.isNotEmpty
                                ? product.imageUrl
                                : 'assets/images/shop/${product.id}.jpg',
                            width: 64,
                            height: 64,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Product Metadata
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  product.price,
                                  style: const TextStyle(
                                    color: AppColors.accentLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.star_rounded,
                                    color: AppColors.warning, size: 13),
                                const SizedBox(width: 2),
                                Text(
                                  '${product.rating}',
                                  style: const TextStyle(
                                    color: AppColors.onSurfaceMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action buttons column
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Wishlist Heart
                          GestureDetector(
                            onTap: () => provider.toggleFavorite(product.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isFav
                                    ? Colors.red.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFav ? Colors.red : Colors.white54,
                                size: 20,
                              ),
                            ),
                          ),

                          // Share Button (Feature 2)
                          GestureDetector(
                            onTap: () {
                              final shareText =
                                  'Check out this plant treatment product from PlantCare AI:\n\n'
                                  '${product.title}\n'
                                  'Price: ${product.price} | ⭐ ${product.rating}\n\n'
                                  '${product.affiliateUrl}';
                              Share.share(shareText, subject: product.title);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.ios_share_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 4),

                      // Buy on Amazon button
                      ElevatedButton(
                        onPressed: () =>
                            provider.logClickAndLaunch(product.id, product.asin),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Buy',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // ── Amazon Affiliate Disclosure ─────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '*As an Amazon Associate, we earn from qualifying purchases.',
                style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    fontStyle: FontStyle.italic),
              ),
            ),

            const SizedBox(height: 12),

            // ── Feature 1: View All in Shop CTA ────────────────
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationShell(initialIndex: 4),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(
                  Icons.storefront_rounded,
                  size: 16,
                  color: AppColors.accentLight,
                ),
                label: const Text(
                  'Browse Full Shop',
                  style: TextStyle(
                    color: AppColors.accentLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
