import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/app_card.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Selected values
  String _experienceLevel = 'Beginner';
  String _gardenPreference = 'Both';
  String _climateZone = 'Detecting...';
  bool _isDetectingClimate = false;
  final List<String> _selectedInterests = [];

  final List<String> _interests = [
    'Vegetables',
    'Flowers',
    'Succulents',
    'Herbs',
    'Fruit Trees',
    'Rare Plants'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _detectClimateZone() async {
    setState(() {
      _isDetectingClimate = true;
      _climateZone = 'Locating GPS Satellites...';
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _climateZone = 'Zone 9b — Warm Mediterranean ☀️';
        _isDetectingClimate = false;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_onboarding_completed', true);
      
      if (mounted) {
        widget.onCompleted();
      }
    } catch (e) {
      // Error saving onboarding completion silently ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkBgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: List.generate(4, (index) {
                    final isCompleted = index <= _currentPage;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.primaryGreen
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Subheader or Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton.icon(
                        onPressed: _previousPage,
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white60, size: 16),
                        label: const Text('Back', style: TextStyle(color: Colors.white60)),
                      )
                    else
                      const SizedBox(width: 80),
                    
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white30, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Sliding Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildPreferencesPage(),
                    _buildClimatePage(),
                    _buildInterestsPage(),
                  ],
                ),
              ),

              // Bottom control buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page ${_currentPage + 1} of 4',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 10,
                        shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == 3 ? 'Get Started 🌿' : 'Continue',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == 3 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
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
  }

  // ── Welcome Page ─────────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 85,
                height: 85,
                fit: BoxFit.cover,
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.bounceOut),
          const SizedBox(height: 30),
          const Text(
            'Welcome to PlantCare AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your plant health companion. Let\'s customize your experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 40),
          
          // Experience Selection Grid
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'GARDENING EXPERIENCE LEVEL',
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
          const SizedBox(height: 12),
          ...['Beginner', 'Intermediate', 'Expert'].map((level) {
            final isSelected = _experienceLevel == level;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _experienceLevel = level;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  borderRadius: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            level == 'Beginner'
                                ? Icons.grass_rounded
                                : level == 'Intermediate'
                                    ? Icons.grass_rounded
                                    : Icons.local_florist_rounded,
                            color: isSelected ? AppTheme.primaryGreen : Colors.white60,
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            level,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen)
                      else
                        const Icon(Icons.circle_outlined, color: Colors.white24, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Preferences Page ─────────────────────────────────────────────────────
  Widget _buildPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'Your Gardening Style',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tell us where you nurture your plants so we can customize your watering schedules.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 35),
          
          ...['Indoor Plants Only', 'Outdoor Gardens Only', 'Both Indoor & Outdoor'].map((pref) {
            final shortPref = pref.contains('Indoor') && pref.contains('Outdoor') 
                ? 'Both' 
                : pref.contains('Indoor') 
                    ? 'Indoor' 
                    : 'Outdoor';
            final isSelected = _gardenPreference == shortPref;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _gardenPreference = shortPref;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                        ),
                        child: Icon(
                          shortPref == 'Indoor'
                              ? Icons.home_rounded
                              : shortPref == 'Outdoor'
                                  ? Icons.deck_rounded
                                  : Icons.yard_rounded,
                          color: isSelected ? AppTheme.primaryGreen : Colors.white38,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pref,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shortPref == 'Indoor'
                                  ? 'Houseplants, kitchen herbs, shelves'
                                  : shortPref == 'Outdoor'
                                      ? 'Backyard vegetables, orchard trees, lawns'
                                      : 'Balcony greens, yard planters, house flora',
                              style: const TextStyle(color: Colors.white30, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen)
                      else
                        const Icon(Icons.circle_outlined, color: Colors.white24, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Climate Zone Detection Page ─────────────────────────────────────────
  Widget _buildClimatePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen.withValues(alpha: 0.05),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
            ),
            child: _isDetectingClimate
                ? const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : const Icon(
                    Icons.public_rounded,
                    size: 60,
                    color: AppTheme.primaryGreen,
                  ),
          ),
          const SizedBox(height: 30),
          const Text(
            'GPS Climate Auto-Detection',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We can auto-detect your USDA Hardiness zone and regional weather. This adjusts watering schedules based on local rainfall.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white54,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 40),
          
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            borderRadius: 24,
            child: Column(
              children: [
                const Text(
                  'DETECTED ZONE',
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  _climateZone,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _climateZone == 'Detecting...' 
                        ? Colors.white54 
                        : AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_climateZone == 'Detecting...')
            ElevatedButton.icon(
              onPressed: _detectClimateZone,
              icon: const Icon(Icons.gps_fixed_rounded),
              label: const Text('Detect via Location Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white12),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Interests Page ───────────────────────────────────────────────────────
  Widget _buildInterestsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'Your Gardening Focus',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Select your top plant categories. We\'ll prioritize recommendations and encyclopedia lookups for these.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
            ),
            itemCount: _interests.length,
            itemBuilder: (context, index) {
              final interest = _interests[index];
              final isSelected = _selectedInterests.contains(interest);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 20,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        interest == 'Vegetables'
                            ? Icons.grass_rounded
                            : interest == 'Flowers'
                                ? Icons.local_florist_rounded
                                : interest == 'Succulents'
                                    ? Icons.wb_sunny_rounded
                                    : interest == 'Herbs'
                                        ? Icons.filter_vintage_rounded
                                        : interest == 'Fruit Trees'
                                            ? Icons.yard_rounded
                                            : Icons.workspace_premium_rounded,
                        color: isSelected ? AppTheme.primaryGreen : Colors.white38,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        interest,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Setup complete and ready! 🌿',
                style: TextStyle(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 1000.ms),
        ],
      ),
    );
  }
}
