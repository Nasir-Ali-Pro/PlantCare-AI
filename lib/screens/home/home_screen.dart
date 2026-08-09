import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/garden_provider.dart';
import '../../providers/diagnosis_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/plant_image.dart';
import '../../widgets/action_card.dart';
import '../../widgets/weather_streak_dashboard.dart';
import '../../services/weather_service.dart';
import '../scanning/scanning_screen.dart';
import '../history/history_screen.dart';
import '../result/result_screen.dart';
import '../forum/forum_screen.dart';
import '../profile/profile_screen.dart';
import '../garden/my_garden_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _supabaseUrlController = TextEditingController();
  final TextEditingController _supabaseKeyController = TextEditingController();
  bool _obscureApiKey = true;
  
  PlantWeatherInfo? _weatherInfo;
  bool _loadingWeather = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DiagnosisProvider>(context, listen: false);
      _apiKeyController.text = provider.geminiApiKey;
      _supabaseUrlController.text = provider.supabaseUrl;
      _supabaseKeyController.text = provider.supabaseAnonKey;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _supabaseUrlController.dispose();
    _supabaseKeyController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    try {
      final weather = await WeatherService().getWeather();
      if (mounted) {
        setState(() {
          _weatherInfo = weather;
          _loadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingWeather = false;
        });
      }
    }
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer<DiagnosisProvider>(
              builder: (context, provider, child) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                final screenHeight = MediaQuery.of(context).size.height;
                return Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: screenHeight * 0.9 - bottomInset,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: AppCard(
                        borderRadius: 24,
                        color: AppColors.surfaceElevated,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.border, height: 24),
                            
                            // API Key Input
                            const Text(
                              'Gemini API Key',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _apiKeyController,
                              obscureText: _obscureApiKey,
                              style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Enter your Gemini API key...',
                                hintStyle: const TextStyle(color: AppColors.onSurfaceFaint, fontSize: 13),
                                prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: AppColors.onSurfaceMuted,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      _obscureApiKey = !_obscureApiKey;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceHighlight,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              onChanged: (val) {
                                provider.setGeminiApiKey(val);
                              },
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                 Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
                                 SizedBox(width: 6),
                                 Expanded(
                                   child: Text(
                                     'Required for detailed plant disease analysis.',
                                     style: TextStyle(
                                       color: AppColors.onSurfaceMuted,
                                       fontSize: 11,
                                     ),
                                   ),
                                 ),
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
          },
        );
      },
    );
  }

  void _navigateToScanning(BuildContext context, ImageSource source) {
    final provider = Provider.of<DiagnosisProvider>(context, listen: false);
    
    provider.reset();
    provider.selectAndDiagnose(source);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanningScreen()),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gardenProvider = Provider.of<GardenProvider>(context);
    final streak = gardenProvider.careStreak;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: gardenProvider.isAdmin
            ? IconButton(
                onPressed: () => _showSettingsModal(context),
                icon: const Icon(Icons.settings_suggest_rounded, size: 26, color: AppColors.onSurface),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PlantCare AI',
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForumScreen()),
              );
            },
            icon: const Icon(Icons.forum_rounded, size: 24, color: AppColors.primary),
            tooltip: 'Community Forum',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            icon: const Icon(Icons.history_edu_rounded, size: 24, color: AppColors.onSurface),
            tooltip: 'Scan History',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final horizontalPadding = constraints.maxWidth < 380 ? 16.0 : 24.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Expressive Header / Branding ───────────────────────
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: theme.textTheme.displayLarge?.copyWith(
                                        fontSize: constraints.maxWidth < 360 ? 24 : 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ).animate().fade(duration: 300.ms).slideY(begin: 0.1),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primaryLight.withValues(alpha: 0.6),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Your botanical assistant is online.',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: AppColors.onSurfaceMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ).animate().fade(duration: 300.ms, delay: 100.ms).slideY(begin: 0.1),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                  );
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.secondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: gardenProvider.avatarUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(26),
                                          child: buildPlantImage(
                                            gardenProvider.avatarUrl,
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.person_outline_rounded,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                ).animate().fade(duration: 350.ms, delay: 150.ms).scale(begin: const Offset(0.8, 0.8)),
                              ),
                            ],
                          ),
                        ),

                        // ── Streak and Weather ──────────────────────────────────
                        WeatherStreakDashboard(
                          careStreak: streak,
                          weatherInfo: _weatherInfo,
                          loadingWeather: _loadingWeather,
                          onRefreshWeather: _fetchWeather,
                        ).animate().fade(duration: 300.ms, delay: 120.ms).slideY(begin: 0.05),
                        
                        // ── Daily Care Tasks Digest ──────────────────────────────
                        _buildDailyCareDigest(context).animate().fade(duration: 300.ms, delay: 150.ms).slideY(begin: 0.05),

                        // ── Scan Mode Selector ──────────────────────────────────
                        _buildScanModeSelector(context).animate().fade(duration: 300.ms, delay: 180.ms).slideY(begin: 0.05),
            
                        // ── Responsive Capture Action Panel ───────────────────────
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
                          child: isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: ActionCard(
                                        title: 'Snap Leaf Photo',
                                        subtitle: 'Use camera to capture single leaf',
                                        icon: Icons.camera_alt_rounded,
                                        isPrimary: true,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        onPressed: () => _navigateToScanning(context, ImageSource.camera),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ActionCard(
                                        title: 'Upload from Gallery',
                                        subtitle: 'Diagnose saved leaf photo',
                                        icon: Icons.photo_library_rounded,
                                        onPressed: () => _navigateToScanning(context, ImageSource.gallery),
                                      ),
                                    ),
                                  ],
                                ).animate().fade(duration: 300.ms, delay: 150.ms).slideY(begin: 0.05)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ActionCard(
                                      title: 'Snap Leaf Photo',
                                      subtitle: 'Use camera to capture single leaf',
                                      icon: Icons.camera_alt_rounded,
                                      isPrimary: true,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      onPressed: () => _navigateToScanning(context, ImageSource.camera),
                                    ).animate().fade(duration: 300.ms, delay: 150.ms).slideX(begin: -0.05),
                                    
                                    const SizedBox(height: 14),
                                    
                                    ActionCard(
                                      title: 'Upload from Gallery',
                                      subtitle: 'Diagnose saved leaf photo',
                                      icon: Icons.photo_library_rounded,
                                      onPressed: () => _navigateToScanning(context, ImageSource.gallery),
                                    ).animate().fade(duration: 300.ms, delay: 200.ms).slideX(begin: 0.05),
                                  ],
                                ),
                        ),
    
                // ── History Carousel ────────────────────────────────────
                Consumer<DiagnosisProvider>(
                  builder: (context, provider, child) {
                    if (provider.history.isEmpty) {
                      return const SizedBox.shrink();
                    }
    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 24.0, top: 16.0, bottom: 12.0),
                          child: Text(
                            'Recent scans',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: provider.history.length,
                            itemBuilder: (context, index) {
                              final report = provider.history[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResultScreen(report: report, fromHistory: true),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 260,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: AppCard(
                                    padding: const EdgeInsets.all(12),
                                    borderRadius: 16,
                                    color: AppColors.surfaceElevated,
                                    borderColor: AppColors.borderLight.withValues(alpha: 0.2),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: buildPlantImage(
                                            report.imagePath,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                report.diseaseName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.onSurface,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                report.plantName,
                                                style: const TextStyle(
                                                  color: AppColors.onSurfaceMuted,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (report.source.toLowerCase().contains('device') 
                                                      ? AppColors.warning 
                                                      : AppColors.primary).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: (report.source.toLowerCase().contains('device') 
                                                        ? AppColors.warning 
                                                        : AppColors.primary).withValues(alpha: 0.25),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Text(
                                                  report.source.toUpperCase(),
                                                  style: TextStyle(
                                                    color: report.source.toLowerCase().contains('device') 
                                                        ? AppColors.warning 
                                                        : AppColors.primaryLight,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 8,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ).animate().fade(duration: 300.ms, delay: 250.ms).slideY(begin: 0.05);
                  },
                ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDailyCareDigest(BuildContext context) {
    final provider = Provider.of<GardenProvider>(context);
    final needyPlants = provider.plants.where((p) => p.needsWatering || p.needsFertilizing).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderLight.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Daily Care Tasks',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                if (needyPlants.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Text(
                      '${needyPlants.length} Alert${needyPlants.length == 1 ? "" : "s"}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.plants.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.10),
                      AppColors.surfaceHighlight.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.grass_rounded, color: AppColors.primaryLight, size: 24),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No Plants in Garden',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add your first plant to start tracking daily watering and fertilizing schedules.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (needyPlants.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.10),
                      AppColors.surfaceHighlight.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.spa_rounded, color: AppColors.primaryLight, size: 24),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'All Plants Healthy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All ${provider.plants.length} plant${provider.plants.length == 1 ? "" : "s"} are currently watered and fertilized.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: needyPlants.length.clamp(0, 3), // Show max 3 alerts
                separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 16),
                itemBuilder: (context, index) {
                  final plant = needyPlants[index];
                  final bool needsWater = plant.needsWatering;
                  final bool needsFertilize = plant.needsFertilizing;

                  return Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: buildPlantImage(
                            plant.imagePath,
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.nickname,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              needsWater && needsFertilize
                                  ? 'Needs water & fertilizer'
                                  : needsWater
                                      ? 'Needs water today'
                                      : 'Needs fertilizer',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceMuted,
                                ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick action buttons styled glossily
                      if (needsWater)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.lightBlue.withValues(alpha: 0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              provider.waterPlant(plant.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${plant.nickname} has been watered.'),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.water_drop_rounded, color: Colors.lightBlue, size: 16),
                            tooltip: 'Water plant',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.lightBlue.withValues(alpha: 0.12),
                              padding: const EdgeInsets.all(8),
                              side: BorderSide(color: Colors.lightBlue.withValues(alpha: 0.35), width: 1),
                            ),
                          ),
                        ),
                      if (needsFertilize)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              provider.fertilizePlant(plant.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${plant.nickname} has been fertilized.'),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.science_rounded, color: Colors.amber, size: 16),
                            tooltip: 'Fertilize plant',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.amber.withValues(alpha: 0.12),
                              padding: const EdgeInsets.all(8),
                              side: BorderSide(color: Colors.amber.withValues(alpha: 0.35), width: 1),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            if (needyPlants.length > 3) ...[
              const Divider(color: AppColors.border, height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyGardenScreen(),
                    ),
                  );
                },
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all care tasks',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primaryLight),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildScanModeSelector(BuildContext context) {
    final diagnosisProvider = Provider.of<DiagnosisProvider>(context);
    final isDiagnose = diagnosisProvider.scanMode == ScanMode.diagnose;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => diagnosisProvider.setScanMode(ScanMode.diagnose),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: isDiagnose 
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ) 
                        : null,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: isDiagnose
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.healing_rounded,
                        color: isDiagnose ? Colors.white : AppColors.onSurfaceMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Diagnose Health',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDiagnose ? Colors.white : AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => diagnosisProvider.setScanMode(ScanMode.identify),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: !isDiagnose 
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ) 
                        : null,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: !isDiagnose
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: !isDiagnose ? Colors.white : AppColors.onSurfaceMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Identify Species',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: !isDiagnose ? Colors.white : AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
