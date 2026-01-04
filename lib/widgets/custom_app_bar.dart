import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types for different screen contexts
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

/// Custom app bar widget for TikTok Analytics app
/// Implements clean, minimal design with contextual actions
///
/// Features:
/// - Multiple variants for different screen contexts
/// - Smooth elevation changes on scroll
/// - Haptic feedback for interactions
/// - Search integration
/// - Badge support for notifications
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar variant type
  final CustomAppBarVariant variant;

  /// Title text
  final String? title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Leading widget (overrides default back button)
  final Widget? leading;

  /// Action widgets displayed on the right
  final List<Widget>? actions;

  /// Search query callback for search variant
  final Function(String)? onSearch;

  /// Initial search query for search variant
  final String? initialSearchQuery;

  /// Notification badge count
  final int? notificationBadgeCount;

  /// Whether to show elevation (for scrolled state)
  final bool elevated;

  /// Custom background color
  final Color? backgroundColor;

  /// Whether to show back button
  final bool showBackButton;

  /// Custom back button callback
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

  /// Standard app bar with title
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

  /// Search app bar with search field
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

  /// Detail app bar with back button
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

  /// Transparent app bar for overlays
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
