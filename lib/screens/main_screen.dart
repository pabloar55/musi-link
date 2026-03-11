import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/components/user_avatar_menu.dart';
import 'package:musi_link/screens/home_screen.dart';
import 'package:musi_link/screens/social_screen.dart';
import 'package:musi_link/screens/stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentPageIndex = 0;
  final PageController _pageController = PageController();
  final List<Widget> screens = [
    const HomeScreen(),
    const StatsScreen(),
    const SocialScreen(),
    Builder(builder: (context) => Center(child: Text(AppLocalizations.of(context)!.navLibrary))),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: l10n.navSocial),
          NavigationDestination(
            icon: Icon(Icons.library_music),
            label: l10n.navLibrary,
          ),
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
