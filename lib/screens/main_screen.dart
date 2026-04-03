import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/widgets/user_avatar_menu.dart';
import 'package:musi_link/screens/discover_screen.dart';
import 'package:musi_link/screens/messages_screen.dart';
import 'package:musi_link/screens/stats_screen.dart';
import 'package:musi_link/screens/friends_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  int currentPageIndex = 0;
  final PageController _pageController = PageController();
  final List<Widget> screens = [
    const DiscoverScreen(),
    const StatsScreen(),
    const MessagesScreen(),
    const FriendsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (ref.read(spotifyServiceProvider).isInitialized) {
      ref.read(spotifyServiceProvider).startPollingNowPlaying();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (ref.read(spotifyServiceProvider).isInitialized) {
        ref.read(spotifyServiceProvider).startPollingNowPlaying();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ref.read(spotifyServiceProvider).stopPollingNowPlaying();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Image.asset('assets/images/logo.png', width: 150),
        actions: const [UserAvatarMenu()],
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        children: screens,
      ),

      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: const Icon(Icons.explore), label: l10n.navDiscover),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: l10n.navStats),
          NavigationDestination(icon: const Icon(Icons.chat_bubble), label: l10n.navMessages),
          NavigationDestination(icon: const Icon(Icons.people), label: l10n.navFriends),
        ],
        selectedIndex: currentPageIndex,

        onDestinationSelected: (int index) {
          _pageController.jumpToPage(index);
          setState(() {
            currentPageIndex = index;
          });
        },
      ),
    );
  }
}
