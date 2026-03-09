import 'package:flutter/material.dart';
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
    const Center(child: Text("Library")),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          NavigationDestination(icon: Icon(Icons.explore), label: 'Descubrir'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: 'Social'),
          NavigationDestination(
            icon: Icon(Icons.library_music),
            label: 'Library',
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
