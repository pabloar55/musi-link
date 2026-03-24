import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/widgets/onboarding/onboarding_page.dart';

/// Pantalla de bienvenida con slider de 5 páginas explicativas.
/// Se muestra solo la primera vez que el usuario inicia sesión.
/// Guarda un flag en SharedPreferences para no volver a mostrarse.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  /// Clave de SharedPreferences para indicar si el onboarding ya se completó.
  static const String onboardingCompletedKey = 'onboarding_completed';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Marca el onboarding como completado y navega a MainScreen.
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.onboardingCompletedKey, true);

    if (!mounted) return;

    context.go('/');
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final pages = [
      OnboardingPage(
        icon: Icons.explore,
        title: l10n.onboardingDiscoverTitle,
        description: l10n.onboardingDiscoverDesc,
      ),
      OnboardingPage(
        icon: Icons.bar_chart,
        title: l10n.onboardingStatsTitle,
        description: l10n.onboardingStatsDesc,
      ),
      OnboardingPage(
        icon: Icons.music_note,
        title: l10n.onboardingDailySongTitle,
        description: l10n.onboardingDailySongDesc,
      ),
      OnboardingPage(
        icon: Icons.chat_bubble,
        title: l10n.onboardingChatTitle,
        description: l10n.onboardingChatDesc,
      ),
      OnboardingPage(
        icon: Icons.people,
        title: l10n.onboardingFriendsTitle,
        description: l10n.onboardingFriendsDesc,
      ),
    ];

    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Botón Skip arriba a la derecha
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    l10n.onboardingSkip,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),

            // PageView con las páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: pages,
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),
            ),

            // Botón Next / Get Started
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLastPage ? _completeOnboarding : _nextPage,
                  child: Text(
                    isLastPage
                        ? l10n.onboardingGetStarted
                        : l10n.onboardingNext,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
