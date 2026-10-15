import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/preferences_service.dart';
import '../../widgets/coin_avatar.dart';

class OnboardingScreen extends StatefulWidget {
  final PreferencesService prefs;
  final VoidCallback onFinish;

  const OnboardingScreen({
    super.key,
    required this.prefs,
    required this.onFinish,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Master Your Personal Wealth',
      'subtitle': 'A refined, private financial manager designed to help you track expenses, analyze cash flow, and grow your net worth.',
      'icon': Icons.account_balance_wallet_outlined,
      'badge': '100% PRIVATE & ON-DEVICE',
    },
    {
      'title': 'Intelligent Financial Analytics',
      'subtitle': 'Interactive spending breakdowns, real-time budget pacing, and automated unusual transaction anomaly alerts.',
      'icon': Icons.insights_rounded,
      'badge': 'PROACTIVE INSIGHTS',
    },
    {
      'title': 'Multi-Account & Transfer Tracking',
      'subtitle': 'Seamlessly manage cash wallets, bank checking, high-yield savings, and credit cards with strict double-entry balance integrity.',
      'icon': Icons.swap_horiz_rounded,
      'badge': 'ACCURATE RECONCILIATION',
    },
    {
      'title': 'Local Privacy & Data Control',
      'subtitle': 'Your financial records remain strictly on your device. Export to CSV anytime or create encrypted JSON backups.',
      'icon': Icons.shield_outlined,
      'badge': 'LOCAL-FIRST ARCHITECTURE',
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    await widget.prefs.setOnboardingCompleted(true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ivoryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CoinAvatar(size: 34),
                      const SizedBox(width: 10),
                      Text(
                        'My Trans Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _complete,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.goldSubtle,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.goldBorder),
                          ),
                          child: Text(
                            page['badge'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Center Graphic Container
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.cardBorder,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldPrimary.withAlpha(isDark ? 40 : 25),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              page['icon'] as IconData,
                              size: 56,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Title
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Subtitle
                        Text(
                          page['subtitle'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator and Buttons
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.goldPrimary
                              : (isDark ? AppColors.darkBorder : AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1 ? 'Get Started' : 'Continue',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
