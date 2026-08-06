import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/garden_provider.dart';
import '../../providers/diagnosis_provider.dart';
import '../../widgets/app_card.dart';
import '../../services/image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadAvatar(
    BuildContext context,
    GardenProvider provider,
  ) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Photo Gallery',
                  style: TextStyle(color: AppColors.onSurface),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: AppColors.onSurface),
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageInfo = await ImageService.pickAndCompressImage(source);
      if (imageInfo == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload profile picture to 'profiles' bucket inside a folder named after username
      final String? publicUrl = await ImageService.uploadImage(
        bucketName: 'profiles',
        bytes: imageInfo.bytes,
        fileName: imageInfo.fileName,
        folderName: provider.username.replaceAll(' ', '_').toLowerCase(),
      );

      if (publicUrl != null) {
        await provider.updateAvatarUrl(publicUrl);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        final base64String = base64Encode(imageInfo.bytes);
        await provider.updateAvatarUrl('data:image/jpeg;base64,$base64String');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture saved locally (offline).'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload image, fell back to local save: $e',
            ),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatJoinDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return 'Joined ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final gardenProvider = Provider.of<GardenProvider>(context);
    final diagnosisProvider = Provider.of<DiagnosisProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gardener Profile'),
        actions: [
          IconButton(
            onPressed: () {
              gardenProvider.logoutUser();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out successfully.'),
                  backgroundColor: AppTheme.bgDarkEnd,
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerRed),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── User Identity Profile Header ─────────────────────────────
                _buildIdentityHeader(context, gardenProvider),
                const SizedBox(height: 24),

                // ── Guest Mode Call to Action Banner ─────────────────────────
                if (gardenProvider.isGuest) ...[
                  _buildGuestBanner(context, gardenProvider),
                  const SizedBox(height: 24),
                ],

                // ── Gardening Streak & Achievements ────────────────────────
                _buildAchievementsCard(context, gardenProvider)
                    .animate()
                    .fade(delay: 50.ms, duration: 400.ms)
                    .slideY(begin: 0.05),
                const SizedBox(height: 24),

                // ── Botanical Statistics Card ────────────────────────────────
                _buildStatsCard(context, gardenProvider, diagnosisProvider)
                    .animate()
                    .fade(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.05),
                const SizedBox(height: 24),

                // ── App Configuration Card (Settings) ────────────────────────
                _buildSettingsCard(context, diagnosisProvider)
                    .animate()
                    .fade(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.05),
                const SizedBox(height: 24),

                // ── Professional Info & Branding Card ────────────────────────
                _buildBrandingCard(context)
                    .animate()
                    .fade(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.05),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context, GardenProvider garden) {
    final achievements = garden.achievements;
    final streak = garden.careStreak;

    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.accentAmber,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievements & badges',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 28),

          // Streak Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: streak > 0
                    ? [
                        const Color(0xFFF97316).withValues(alpha: 0.15),
                        const Color(0xFFEAB308).withValues(alpha: 0.15),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.03),
                        Colors.white.withValues(alpha: 0.03),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: streak > 0
                    ? const Color(0xFFF97316).withValues(alpha: 0.4)
                    : Colors.white12,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '🔥',
                  style: TextStyle(
                    fontSize: 24,
                    shadows: streak > 0
                        ? [
                            const Shadow(
                              color: Color(0xFFF97316),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streak > 0
                            ? '$streak-Day Care Streak!'
                            : 'No Active Streak',
                        style: TextStyle(
                          color: streak > 0
                              ? const Color(0xFFF97316)
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        streak > 0
                            ? 'You are actively caring for your garden. Keep it up!'
                            : 'Perform care tasks daily to build your gardening streak.',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid of Badges
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final ach = achievements[index];
              final bool isUnlocked = ach['isUnlocked'] ?? false;
              final IconData icon = ach['icon'] as IconData;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isUnlocked
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUnlocked
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                      ),
                      child: Icon(
                        icon,
                        color: isUnlocked ? AppColors.primary : Colors.white38,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ach['title'] ?? '',
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ach['description'] ?? '',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 9.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Identity Header widget
  Widget _buildIdentityHeader(BuildContext context, GardenProvider provider) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          GestureDetector(
            onTap: provider.isGuest
                ? null
                : () => _pickAndUploadAvatar(context, provider),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.bgDarkEnd,
                    backgroundImage: provider.avatarUrl.isNotEmpty
                        ? (provider.avatarUrl.startsWith('data:')
                              ? MemoryImage(
                                      base64Decode(
                                        provider.avatarUrl.split(',').last,
                                      ),
                                    )
                                    as ImageProvider
                              : CachedNetworkImageProvider(provider.avatarUrl)
                                    as ImageProvider)
                        : null,
                    child: provider.avatarUrl.isNotEmpty
                        ? null
                        : Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen,
                                  Color(0xFF047857),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                provider.username.isNotEmpty
                                    ? provider.username[0].toUpperCase()
                                    : 'G',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  )
                else if (!provider.isGuest)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  provider.username,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditNameModal(context, provider),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${provider.joinedAt != null ? _formatJoinDate(provider.joinedAt!) : 'May 2026'} • ${provider.isGuest ? "Guest" : "Member"}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Guest Banner widget
  Widget _buildGuestBanner(BuildContext context, GardenProvider provider) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppTheme.accentAmber,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Unlock Full Experience!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'You are currently exploring in Guest Mode. Register or log in now to save your virtual garden permanently, participate in community forums, and track your plant care journal!',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              provider.logoutUser();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Redirecting to Registration... 🔒'),
                  backgroundColor: AppTheme.bgDarkEnd,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Register or Log In',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  // Botanical Statistics widget
  Widget _buildStatsCard(
    BuildContext context,
    GardenProvider garden,
    DiagnosisProvider diagnosis,
  ) {
    // Calculate average health of plants
    double avgHealth = 0.0;
    if (garden.plants.isNotEmpty) {
      final totalHealth = garden.plants.fold<double>(
        0,
        (sum, plant) => sum + (plant.healthScore / 100.0),
      );
      avgHealth = totalHealth / garden.plants.length;
    }

    // Plants needing water/fertilizer
    int thirstyCount = garden.plants.where((p) => p.needsWatering).length;

    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Botanical statistics',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 28),

          // Stats Row 1
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context: context,
                  icon: Icons.yard_rounded,
                  color: AppTheme.primaryGreen,
                  value: '${garden.plants.length}',
                  label: 'Plants Tracked',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context: context,
                  icon: Icons.health_and_safety_rounded,
                  color: avgHealth >= 0.8
                      ? AppTheme.primaryGreen
                      : (avgHealth >= 0.5
                            ? AppTheme.accentAmber
                            : AppTheme.dangerRed),
                  value: garden.plants.isEmpty
                      ? 'N/A'
                      : '${(avgHealth * 100).toInt()}%',
                  label: 'Avg Garden Health',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Row 2
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context: context,
                  icon: Icons.water_drop_rounded,
                  color: thirstyCount > 0
                      ? AppTheme.accentAmber
                      : AppTheme.primaryGreen,
                  value: '$thirstyCount',
                  label: 'Thirsty Plants',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context: context,
                  icon: Icons.science_rounded,
                  color: Colors.blueAccent,
                  value: '${diagnosis.history.length}',
                  label: 'Pathology Reports',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // App Settings widget
  Widget _buildSettingsCard(BuildContext context, DiagnosisProvider provider) {
    String obfuscateApiKey(String key) {
      if (key.isEmpty) return 'Not Configured';
      if (key.length <= 10) return '••••••••••';
      return '${key.substring(0, 7)}••••••••••••${key.substring(key.length - 4)}';
    }

    final maskedKey = obfuscateApiKey(provider.geminiApiKey);

    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_suggest_rounded,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Configuration & utilities',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 28),

          // Gemini Key row
          if (Provider.of<GardenProvider>(context).isAdmin) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    color: Colors.blueAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gemini AI API Key',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        maskedKey,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showApiKeyModal(context, provider),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Manage',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 24),
          ],

          // Clear history row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: AppTheme.dangerRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clear Diagnostic Cache',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Removes all ${provider.history.length} saved diagnostic records',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showClearHistoryConfirm(context, provider),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.dangerRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Professional Branding widget
  Widget _buildBrandingCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'PlantCare AI',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'A BSCS Final Year Project',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.onSurfaceMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const Divider(color: AppColors.border, height: 28),
          const Text(
            'Your Smart Plant Doctor & Care Companion',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.onSurfaceMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryConfirm(
    BuildContext context,
    DiagnosisProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.bgDarkStart,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Clear Diagnostics Cache? 🧹'),
          content: const Text(
            'This action will permanently delete all saved diagnosis reports from your local database. This cannot be undone.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                provider.clearHistory();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Diagnostics history cleared successfully.'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete All',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditNameModal(BuildContext context, GardenProvider provider) {
    final textController = TextEditingController(text: provider.username);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AppCard(
            borderRadius: 30,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Update Profile Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 16),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Gardener Name',
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryGreen,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final newName = textController.text.trim();
                    if (newName.isNotEmpty) {
                      provider.loginUser(newName);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile name updated.'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showApiKeyModal(
    BuildContext context,
    DiagnosisProvider diagnosisProvider,
  ) {
    final textController = TextEditingController(
      text: diagnosisProvider.geminiApiKey,
    );
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: AppCard(
                borderRadius: 30,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.vpn_key_rounded,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Global Gemini API Key',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    const Text(
                      'This key is stored in Supabase and used by all app users. Keep it secure.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'API Key (starts with AIza...)',
                        labelStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.vpn_key_rounded,
                          color: AppTheme.primaryGreen,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryGreen,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final key = textController.text.trim();
                              if (key.isEmpty) return;

                              setSheetState(() => isSaving = true);

                              // 1. Update locally + in ChatProvider
                              await diagnosisProvider.setGeminiApiKey(key);

                              // 2. Push to Supabase admin row (via GardenProvider)
                              final success = await gardenProvider
                                  .updateAdminGeminiKey(key);

                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? '✅ Gemini API key saved globally to Supabase.'
                                          : '⚠️ Key saved locally. Supabase sync failed — check connection.',
                                    ),
                                    backgroundColor: success
                                        ? AppTheme.primaryGreen
                                        : Colors.orange,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save & Sync to Supabase',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
}
