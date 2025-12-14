import 'package:flutter/material.dart';
import 'package:musi_link/components/mi_navigation_bar.dart';
import 'package:musi_link/screens/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Musi.link")),

      body: [HomeScreen()][currentPageIndex],

      bottomNavigationBar: MiNavigationBar(),
    );
  }
}
