import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/widgets/user_avatar_menu.dart';
import 'package:musi_link/screens/discover_screen.dart';
import 'package:musi_link/screens/messages_screen.dart';
import 'package:musi_link/screens/stats_screen.dart';
import 'package:musi_link/screens/friends_screen.dart';
import 'package:musi_link/services/spotify_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
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
    if (SpotifyService.instance.isInitialized) {
      SpotifyService.instance.startPollingNowPlaying();
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
      if (SpotifyService.instance.isInitialized) {
        SpotifyService.instance.startPollingNowPlaying();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      SpotifyService.instance.stopPollingNowPlaying();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', width: 150),
        actions: [const UserAvatarMenu()],
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
          NavigationDestination(icon: Icon(Icons.explore), label: l10n.navDiscover),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: l10n.navStats),
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: l10n.navMessages),
          NavigationDestination(icon: Icon(Icons.people), label: l10n.navFriends),
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
