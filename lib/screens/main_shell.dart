import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'list_screen.dart';
import 'watchlist_screen.dart';
import 'guide_screen.dart';

/// Container utama dengan navigasi BottomNavigationBar 4 tab
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToList: () => _onTabSelected(1),
      ),
      const ListScreen(),
      WatchlistScreen(
        onNavigateToHome: () => _onTabSelected(0),
      ),
      const GuideScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted_outlined),
            selectedIcon: Icon(Icons.format_list_bulleted_rounded),
            label: 'Daftar Gempa',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Pantauan Saya',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety_rounded),
            label: 'Panduan Siaga',
          ),
        ],
      ),
    );
  }
}
