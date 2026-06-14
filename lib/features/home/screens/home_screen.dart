import 'package:flutter/material.dart';
import 'package:drunk_diary/core/navigation/tab_change_notification.dart';

import '../../activity/screens/diary_screen.dart';
import '../../drink_logs/screens/shelf_screen.dart';
import '../../drink_logs/screens/unified_logging_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/screens/search_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding/presentation/providers/post_onboarding_action_handler.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstLogGuidance();
  }

  void _checkFirstLogGuidance() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final guidance = ref.read(postOnboardingHandlerProvider);
      if (guidance.shouldShowFirstLogGuidance && !guidance.hasTriggered) {
        // Delay slightly to let the home screen settle
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _openUnifiedLoggingScreen();
            ref.read(postOnboardingHandlerProvider.notifier).markAsTriggered();
          }
        });
      }
    });
  }

  void _openUnifiedLoggingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UnifiedLoggingScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildTab(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          MaterialPageRoute(builder: (context) => child),
        ];
      },
      onGenerateRoute: (settings) {
        // This handles pushes inside the tab
        return null; // Let it bubble up to root if not handled here
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final navigator = _navigatorKeys[_currentIndex].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: NotificationListener<TabChangeNotification>(
          onNotification: (notification) {
            if (notification.index == 2) {
              _openUnifiedLoggingScreen();
            } else {
              if (_currentIndex == notification.index) {
                _navigatorKeys[_currentIndex].currentState?.popUntil((r) => r.isFirst);
              } else {
                setState(() => _currentIndex = notification.index);
              }
            }
            return true;
          },
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildTab(0, const DiaryScreen()),
              _buildTab(1, const SearchScreen()),
              const SizedBox.shrink(),
              _buildTab(3, const ShelfScreen()),
              _buildTab(4, const ProfileScreen()),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              _openUnifiedLoggingScreen();
            } else {
              if (_currentIndex == index) {
                // Pop to root if already on this tab
                _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
              } else {
                setState(() => _currentIndex = index);
              }
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
                  color: Colors.amber.withValues(alpha: 0.1),
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
      ),
    );
  }
}
