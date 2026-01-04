import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation item configuration for bottom bar
/// Internal class that defines each tab in the bottom navigation
class _NavigationItem {
  final String label; // Text shown under icon
  final IconData icon; // Icon when tab is not selected
  final IconData activeIcon; // Icon when tab is selected
  final String route; // Screen route to navigate to

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

/// Custom Bottom Navigation Bar - Main navigation for the app
///
/// This widget provides the bottom tab bar that appears on all main screens.
/// It lets users quickly switch between the 5 main sections of the app.
///
/// Features:
/// - 5 fixed tabs: Dashboard, Followers, Following, Analytics, Profile
/// - Haptic feedback (phone vibrates) when switching tabs
/// - Smooth 200ms transition animations
/// - Badge support for notifications (shown on Profile tab)
/// - Adaptive elevation and shadows
/// - Thumb-optimized positioning (easy to reach with thumb)
///
/// The 5 tabs:
/// 1. Dashboard - Overview of your TikTok metrics
/// 2. Followers - Manage your followers
/// 3. Following - Manage accounts you follow
/// 4. Analytics - Deep insights and charts
/// 5. Profile - Your profile and notifications
///
/// Usage:
/// ```dart
/// CustomBottomBar(
///   currentRoute: '/dashboard-screen',
///   notificationBadgeCount: 3, // Shows "3" badge on Profile tab
/// )
/// ```
class CustomBottomBar extends StatelessWidget {
  /// Current active route path (e.g., '/dashboard-screen')
  /// Used to highlight the active tab
  final String currentRoute;

  /// Number of unread notifications to show as badge on Profile tab
  /// If null or 0, no badge is shown
  final int? notificationBadgeCount;

  /// Callback when user taps a navigation item
  /// Receives the route path of the tapped tab
  final Function(String route)? onNavigate;

  const CustomBottomBar({
    super.key,
    required this.currentRoute,
    this.notificationBadgeCount,
    this.onNavigate,
  });

  // All 5 navigation tabs with their icons and routes
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

  /// Get the index of the currently active tab
  /// Returns 0 (Dashboard) if current route doesn't match any tab
  int get _currentIndex {
    final index = _navigationItems.indexWhere(
      (item) => item.route == currentRoute,
    );
    return index >= 0 ? index : 0;
  }

  /// Handle navigation when user taps a tab
  /// - Does nothing if tapping the already active tab
  /// - Vibrates phone for feedback
  /// - Navigates to the selected screen
  void _handleNavigation(BuildContext context, int index) {
    if (index == _currentIndex) return; // Already on this tab

    // Vibrate phone for feedback
    HapticFeedback.lightImpact();

    final route = _navigationItems[index].route;

    // Use custom callback if provided, otherwise use default navigation
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
      // Shadow above the bottom bar
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
        top: false, // Don't add padding at top
        child: Container(
          height: 64, // Fixed height for consistency
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

  /// Build a single navigation tab item
  /// Shows icon, label, and optional badge
  Widget _buildNavigationItem(
    BuildContext context,
    int index,
    _NavigationItem item,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = index == _currentIndex;

    // Show badge on Profile tab (index 4) if there are notifications
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
