import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/ripple_widgets.dart';

class MainNavigationShell extends ConsumerWidget {
  final Widget child;
  const MainNavigationShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/matches')) return 1;
    if (location.startsWith('/chats')) return 2;
    if (location.startsWith('/insights')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/matches');
        break;
      case 2:
        context.go('/chats');
        break;
      case 3:
        context.go('/insights');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final primaryColor = Theme.of(context).primaryColor;

    return RtlSupport(
      child: Scaffold(
        extendBody: false, // Content lays out above the floating nav capsule
        body: child,
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Slate 900 capsule
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    index: 0,
                    selectedIndex: selectedIndex,
                    activeIcon: Icons.dashboard_rounded,
                    inactiveIcon: Icons.dashboard_outlined,
                    primaryColor: primaryColor,
                  ),
                  _buildNavItem(
                    context,
                    index: 1,
                    selectedIndex: selectedIndex,
                    activeIcon: Icons.search_rounded,
                    inactiveIcon: Icons.search_outlined,
                    primaryColor: primaryColor,
                  ),
                  _buildNavItem(
                    context,
                    index: 2,
                    selectedIndex: selectedIndex,
                    activeIcon: Icons.chat_bubble_rounded,
                    inactiveIcon: Icons.chat_bubble_outline_rounded,
                    primaryColor: primaryColor,
                  ),
                  _buildNavItem(
                    context,
                    index: 3,
                    selectedIndex: selectedIndex,
                    activeIcon: Icons.help_rounded,
                    inactiveIcon: Icons.help_outline_rounded,
                    primaryColor: primaryColor,
                  ),
                  _buildNavItem(
                    context,
                    index: 4,
                    selectedIndex: selectedIndex,
                    activeIcon: Icons.person_rounded,
                    inactiveIcon: Icons.person_outline_rounded,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int selectedIndex,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color primaryColor,
  }) {
    final bool isActive = index == selectedIndex;

    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 52 : 44,
        height: isActive ? 52 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? primaryColor : Colors.transparent,
        ),
        child: Center(
          child: Icon(
            isActive ? activeIcon : inactiveIcon,
            color: isActive ? Colors.black : Colors.white60,
            size: isActive ? 24 : 22,
          ),
        ),
      ),
    );
  }
}
