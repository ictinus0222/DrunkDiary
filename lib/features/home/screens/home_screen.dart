import 'package:flutter/material.dart';
import 'package:drunk_diary/core/navigation/tab_change_notification.dart';

import '../../activity/screens/diary_screen.dart';
import '../../drink_logs/screens/shelf_screen.dart';
import '../../drink_logs/screens/unified_logging_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DiaryScreen(), // Tab 0: Diary
    SearchScreen(), // Tab 1: Discover
    SizedBox.shrink(), // Tab 2: Placeholder for Log Action
    ShelfScreen(), // Tab 3: Shelf
    ProfileScreen(), // Tab 4: Profile
  ];

  void _openUnifiedLoggingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UnifiedLoggingScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<TabChangeNotification>(
        onNotification: (notification) {
          if (notification.index == 2) {
            _openUnifiedLoggingScreen();
          } else {
            setState(() => _currentIndex = notification.index);
          }
          return true; // Stop bubbling
        },
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _openUnifiedLoggingScreen();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Diary',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.amber,
                size: 28,
              ),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_bar_outlined),
            activeIcon: Icon(Icons.local_bar),
            label: 'Shelf',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
