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

class _MainNavigationShellState extends State<MainNavigationShell>
    with TickerProviderStateMixin {
  late int _currentIndex;
  bool _isLoading = true;
  bool _isOnboardingCompleted = false;

  late AnimationController _pillController;

  final List<Widget> _tabs = const [
    HomeScreen(),
    MyGardenScreen(),
    ChatScreen(),
    EncyclopediaScreen(),
    ShopScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    _NavItem(Icons.eco_rounded, Icons.eco_outlined, 'Scan'),
    _NavItem(Icons.yard_rounded, Icons.yard_outlined, 'Garden'),
    _NavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'AI Care'),
    _NavItem(Icons.menu_book_rounded, Icons.menu_book_outlined, 'Explore'),
    _NavItem(Icons.shopping_bag_rounded, Icons.shopping_bag_outlined, 'Shop'),
    _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkOnboarding();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pillController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final diagnosisProvider =
          Provider.of<DiagnosisProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.init(diagnosisProvider.geminiApiKey);
    });
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOnboardingCompleted =
          prefs.getBool('pref_onboarding_completed') ?? false;
      _isLoading = false;
    });
  }

  void _onTabTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pillController.reset();
    _pillController.forward();

    if (index == 2) {
      final diagnosisProvider =
          Provider.of<DiagnosisProvider>(context, listen: false);
      Provider.of<ChatProvider>(context, listen: false)
          .init(diagnosisProvider.geminiApiKey);
    }
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
              final diagnosisProvider =
                  Provider.of<DiagnosisProvider>(context, listen: false);
              diagnosisProvider.fetchCentralApiKey().then((_) {
                if (!context.mounted) return;
                final chatProvider =
                    Provider.of<ChatProvider>(context, listen: false);
                chatProvider.init(diagnosisProvider.geminiApiKey);
              });
              _checkOnboarding();
            },
          );
        }

        if (!_isOnboardingCompleted) {
          return OnboardingScreen(
            onCompleted: () {
              setState(() => _isOnboardingCompleted = true);
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
          bottomNavigationBar: _buildNavBar(context),
        );
      },
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.borderLight.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < _navItems.length; i++)
                      if (i == 4)
                        Consumer<ShopProvider>(
                          builder: (_, shopProvider, __) => _buildNavItem(
                            i,
                            _navItems[i],
                            badgeCount: shopProvider.wishlist.length,
                          ),
                        )
                      else
                        _buildNavItem(i, _navItems[i]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    _NavItem item, {
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    width: 1,
                  ),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      isSelected ? item.filledIcon : item.outlinedIcon,
                      key: ValueKey<bool>(isSelected),
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceFaint,
                      size: 22,
                    ),
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
                          color: AppColors.danger,
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
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceFaint,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: isSelected ? 0.1 : 0,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData filledIcon;
  final IconData outlinedIcon;
  final String label;
  const _NavItem(this.filledIcon, this.outlinedIcon, this.label);
}
