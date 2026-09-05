// lib/core/shell/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_dock.dart';
import '../router/app_router.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _baseNavItems = [
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    NavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Connect'),
    NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble_rounded, label: 'Chat'),
    NavItem(icon: Icons.work_outline, activeIcon: Icons.work_rounded, label: 'Jobs'),
    NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  static const _routes = [
    AppRoutes.home,
    AppRoutes.connect,
    AppRoutes.chat,
    AppRoutes.jobs,
    AppRoutes.profile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i].split('/:').first)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _currentIndex(context);
    final chatUnread = ref.watch(chatUnreadCountProvider).value ?? 0;
    final jobsNew = ref.watch(jobsNewCountProvider).value ?? 0;
    final navItems = [
      _baseNavItems[0],
      _baseNavItems[1],
      _baseNavItems[2].copyWith(badgeCount: chatUnread),
      _baseNavItems[3].copyWith(badgeCount: jobsNew),
      _baseNavItems[4],
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: child,
      extendBody: true,
      bottomNavigationBar: BottomNavDock(
        currentIndex: index,
        items: navItems,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }
}
