import 'package:flutter/material.dart';
import 'package:drunk_diary/core/navigation/tab_change_notification.dart';

import '../../activity/screens/diary_screen.dart';
import '../../drink_logs/screens/shelf_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../wishlist/screens/wishlist_screen.dart';

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
    WishlistScreen(), // Tab 1: Wishlist
    SearchScreen(), // Tab 2: Discover
    ShelfScreen(), // Tab 3: Shelf
    ProfileScreen(), // Tab 4: Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<TabChangeNotification>(
        onNotification: (notification) {
          setState(() => _currentIndex = notification.index);
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
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Diary',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentIndex == 2
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.amber.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                color: _currentIndex == 2 ? Colors.amber : Colors.grey.shade600,
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
