import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation item configuration for bottom bar
class _NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

/// Custom bottom navigation bar widget for TikTok Analytics app
/// Implements thumb-optimized bottom-heavy interaction design with haptic feedback
///
/// Features:
/// - Fixed 5-tab navigation for primary workflows
/// - Haptic feedback on tab selection
/// - Smooth 200ms transitions
/// - Badge support for notifications
/// - Adaptive elevation and shadows
class CustomBottomBar extends StatelessWidget {
  /// Current active route path
  final String currentRoute;

  /// Optional badge count for notifications tab
  final int? notificationBadgeCount;

  /// Callback when navigation item is tapped
  final Function(String route)? onNavigate;

  const CustomBottomBar({
    super.key,
    required this.currentRoute,
    this.notificationBadgeCount,
    this.onNavigate,
  });

  // Navigation items mapped to app routes
  static const List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      route: '/dashboard-screen',
    ),
    _NavigationItem(
      label: 'Followers',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      route: '/followers-list-screen',
    ),
    _NavigationItem(
      label: 'Following',
      icon: Icons.person_add_outlined,
      activeIcon: Icons.person_add,
      route: '/following-list-screen',
    ),
    _NavigationItem(
      label: 'Analytics',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      route: '/analytics-screen',
    ),
    _NavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: '/profile-detail-screen',
    ),
  ];

  int get _currentIndex {
    final index = _navigationItems.indexWhere(
      (item) => item.route == currentRoute,
    );
    return index >= 0 ? index : 0;
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == _currentIndex) return;

    // Haptic feedback for tab switch
    HapticFeedback.lightImpact();

    final route = _navigationItems[index].route;

    if (onNavigate != null) {
      onNavigate!(route);
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navigationItems.length,
              (index) =>
                  _buildNavigationItem(context, index, _navigationItems[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    int index,
    _NavigationItem item,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = index == _currentIndex;

    // Show badge on Profile tab (index 4) for notifications
    final showBadge =
        index == 4 &&
        notificationBadgeCount != null &&
        notificationBadgeCount! > 0;

    return Expanded(
      child: InkWell(
        onTap: () => _handleNavigation(context, index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey(isSelected),
                      size: 24,
                      color: isSelected
                          ? colorScheme.primary
                          : theme.bottomNavigationBarTheme.unselectedItemColor,
                    ),
                  ),
                  if (showBadge)
                    Positioned(right: -8, top: -4, child: _buildBadge(context)),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style:
                    (isSelected
                        ? theme.bottomNavigationBarTheme.selectedLabelStyle
                        : theme
                              .bottomNavigationBarTheme
                              .unselectedLabelStyle) ??
                    theme.textTheme.labelSmall!,
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : theme.bottomNavigationBarTheme.unselectedItemColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = notificationBadgeCount!;
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.surface, width: 2),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        displayCount,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onError,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
