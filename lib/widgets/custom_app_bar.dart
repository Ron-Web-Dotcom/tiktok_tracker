import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App Bar Variants - Different styles for different screens
enum CustomAppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with search functionality
  search,

  /// App bar with back button and title
  detail,

  /// Transparent app bar for overlays
  transparent,
}

/// Custom App Bar Widget - Reusable top bar for all screens
///
/// This widget provides a consistent app bar design across the app.
/// It adapts to different screen needs with multiple variants.
///
/// Features:
/// - Multiple styles (standard, search, detail, transparent)
/// - Smooth elevation changes when scrolling
/// - Haptic feedback (phone vibrates) when tapping buttons
/// - Search integration for search screens
/// - Notification badge support
/// - Custom back button handling
///
/// Usage Examples:
/// ```dart
/// // Standard app bar with title
/// CustomAppBar.standard(title: 'Dashboard')
///
/// // App bar with search field
/// CustomAppBar.search(onSearch: (query) => print(query))
///
/// // Detail screen with back button
/// CustomAppBar.detail(title: 'Profile Details')
/// ```
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Which style of app bar to use
  final CustomAppBarVariant variant;

  /// Main title text displayed in the app bar
  final String? title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Custom widget to show on the left (overrides default back button)
  final Widget? leading;

  /// Action buttons displayed on the right side
  final List<Widget>? actions;

  /// Callback when user types in search field (search variant only)
  final Function(String)? onSearch;

  /// Initial text in search field (search variant only)
  final String? initialSearchQuery;

  /// Number to show in notification badge (e.g., "3" unread)
  final int? notificationBadgeCount;

  /// Whether to show shadow under app bar (when scrolled)
  final bool elevated;

  /// Custom background color (uses theme color if not specified)
  final Color? backgroundColor;

  /// Whether to show back button
  final bool showBackButton;

  /// Custom action when back button is pressed
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    this.variant = CustomAppBarVariant.standard,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.onSearch,
    this.initialSearchQuery,
    this.notificationBadgeCount,
    this.elevated = false,
    this.backgroundColor,
    this.showBackButton = false,
    this.onBackPressed,
  });

  /// Create a standard app bar with title
  const CustomAppBar.standard({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.notificationBadgeCount,
    this.elevated = false,
    this.backgroundColor,
  }) : variant = CustomAppBarVariant.standard,
       leading = null,
       onSearch = null,
       initialSearchQuery = null,
       showBackButton = false,
       onBackPressed = null;

  /// Create a search app bar with search field
  const CustomAppBar.search({
    super.key,
    required this.onSearch,
    this.initialSearchQuery,
    this.actions,
    this.elevated = false,
    this.backgroundColor,
  }) : variant = CustomAppBarVariant.search,
       title = null,
       subtitle = null,
       leading = null,
       notificationBadgeCount = null,
       showBackButton = false,
       onBackPressed = null;

  /// Create a detail app bar with back button
  const CustomAppBar.detail({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBackPressed,
    this.elevated = false,
    this.backgroundColor,
  }) : variant = CustomAppBarVariant.detail,
       leading = null,
       onSearch = null,
       initialSearchQuery = null,
       notificationBadgeCount = null,
       showBackButton = true;

  /// Create a transparent app bar for overlays
  const CustomAppBar.transparent({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  }) : variant = CustomAppBarVariant.transparent,
       subtitle = null,
       leading = null,
       onSearch = null,
       initialSearchQuery = null,
       notificationBadgeCount = null,
       elevated = false,
       backgroundColor = Colors.transparent;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBackgroundColor =
        backgroundColor ??
        (variant == CustomAppBarVariant.transparent
            ? Colors.transparent
            : colorScheme.surface);

    return AppBar(
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: variant == CustomAppBarVariant.transparent
          ? Colors.white
          : colorScheme.onSurface,
      elevation: elevated ? 2 : 0,
      scrolledUnderElevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      centerTitle: false,
      leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: _buildActions(context),
      systemOverlayStyle: variant == CustomAppBarVariant.transparent
          ? SystemUiOverlayStyle.light
          : theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showBackButton || variant == CustomAppBarVariant.detail) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
        tooltip: 'Back',
      );
    }

    return null;
  }

  Widget? _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    switch (variant) {
      case CustomAppBarVariant.search:
        return _SearchField(
          onSearch: onSearch!,
          initialQuery: initialSearchQuery,
        );

      case CustomAppBarVariant.standard:
      case CustomAppBarVariant.detail:
      case CustomAppBarVariant.transparent:
        if (title == null) return null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title!, style: theme.appBarTheme.titleTextStyle),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: variant == CustomAppBarVariant.transparent
                      ? Colors.white70
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
    }
  }

  List<Widget>? _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actionWidgets = <Widget>[];

    // Add custom actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    // Add notification badge if count provided
    if (notificationBadgeCount != null && notificationBadgeCount! > 0) {
      actionWidgets.add(
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationBadgeCount! > 9
                        ? '9+'
                        : notificationBadgeCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onError,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/notifications-screen');
          },
          tooltip: 'Notifications',
        ),
      );
    }

    return actionWidgets.isEmpty ? null : actionWidgets;
  }
}

/// Internal search field widget for search variant
class _SearchField extends StatefulWidget {
  final Function(String) onSearch;
  final String? initialQuery;

  const _SearchField({required this.onSearch, this.initialQuery});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onSearch,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search followers...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _controller.clear();
                    widget.onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
