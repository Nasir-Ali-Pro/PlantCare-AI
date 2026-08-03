import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../providers/diagnosis_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/garden_provider.dart';
import '../providers/shop_provider.dart';
import 'home/home_screen.dart';
import 'garden/my_garden_screen.dart';
import 'chat/chat_screen.dart';
import 'encyclopedia/encyclopedia_screen.dart';
import 'profile/profile_screen.dart';
import 'shop/shop_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'auth/auth_screen.dart';
import '../widgets/offline_banner.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  bool _isLoading = true;
  bool _isOnboardingCompleted = false;

  final List<Widget> _tabs = const [
    HomeScreen(),
    MyGardenScreen(),
    ChatScreen(),
    EncyclopediaScreen(),
    ShopScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkOnboarding();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final diagnosisProvider = Provider.of<DiagnosisProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.init(diagnosisProvider.geminiApiKey);
    });
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOnboardingCompleted = prefs.getBool('pref_onboarding_completed') ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Consumer<GardenProvider>(
      builder: (context, gardenProvider, child) {
        if (!gardenProvider.isLoggedIn && !gardenProvider.isGuest) {
          return AuthScreen(
            onAuthenticated: () {
              // Fetch central key on login/auth
              final diagnosisProvider = Provider.of<DiagnosisProvider>(context, listen: false);
              diagnosisProvider.fetchCentralApiKey().then((_) {
                if (!context.mounted) return;
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                chatProvider.init(diagnosisProvider.geminiApiKey);
              });
              _checkOnboarding();
            },
          );
        }

        if (!_isOnboardingCompleted) {
          return OnboardingScreen(
            onCompleted: () {
              setState(() {
                _isOnboardingCompleted = true;
              });
            },
          );
        }

        return Scaffold(
          extendBody: true,
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _tabs,
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.borderLight.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(0, Icons.eco_rounded, Icons.eco_outlined, 'Scan'),
                          _buildNavItem(1, Icons.yard_rounded, Icons.yard_outlined, 'Garden'),
                          _buildNavItem(2, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'AI Care'),
                          _buildNavItem(3, Icons.menu_book_rounded, Icons.menu_book_outlined, 'Explore'),
                          Consumer<ShopProvider>(
                            builder: (_, shopProvider, __) => _buildNavItem(
                              4,
                              Icons.shopping_bag_rounded,
                              Icons.shopping_bag_outlined,
                              'Shop',
                              badgeCount: shopProvider.wishlist.length,
                            ),
                          ),
                          _buildNavItem(5, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    IconData filledIcon,
    IconData outlinedIcon,
    String label, {
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });

          if (index == 2) {
            final diagnosisProvider = Provider.of<DiagnosisProvider>(context, listen: false);
            Provider.of<ChatProvider>(context, listen: false).init(diagnosisProvider.geminiApiKey);
          }
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with optional badge overlay
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? filledIcon : outlinedIcon,
                    color: isSelected ? AppColors.primary : AppColors.onSurfaceFaint,
                    size: 24,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -5,
                      right: -8,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.elasticOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: badgeCount > 9 ? 4.0 : 5.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.danger,
                              AppColors.danger.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (isSelected)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.onSurface : AppColors.onSurfaceFaint,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
