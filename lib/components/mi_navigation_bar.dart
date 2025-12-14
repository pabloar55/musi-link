import 'package:flutter/material.dart';

class MiNavigationBar extends StatefulWidget {
  const MiNavigationBar({super.key});

  @override
  State<MiNavigationBar> createState() => _MiNavigationBarState();
}

class _MiNavigationBarState extends State<MiNavigationBar> {
  var currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
          destinations: [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(
              icon: Icon(Icons.library_music),
              label: 'Library',
            ),
          ],
          selectedIndex: currentPageIndex,
          onDestinationSelected: (int index){
            setState(() {
              currentPageIndex = index;
            });
          },
        );
  }
}