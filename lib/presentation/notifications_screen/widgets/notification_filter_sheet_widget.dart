import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Bottom sheet widget for filtering notifications
///
/// Features:
/// - Filter by notification type
/// - Toggle unread only
/// - Clear all filters
/// - Smooth animations
class NotificationFilterSheetWidget extends StatefulWidget {
  final String selectedFilter;
  final bool showUnreadOnly;
  final Function(String filter, bool unreadOnly) onFilterChanged;

  const NotificationFilterSheetWidget({
    super.key,
    required this.selectedFilter,
    required this.showUnreadOnly,
    required this.onFilterChanged,
  });

  @override
  State<NotificationFilterSheetWidget> createState() =>
      _NotificationFilterSheetWidgetState();
}

class _NotificationFilterSheetWidgetState
    extends State<NotificationFilterSheetWidget> {
  late String _selectedFilter;
  late bool _showUnreadOnly;

  final List<Map<String, dynamic>> _filterOptions = [
    {"value": "all", "label": "All Notifications", "icon": "notifications"},
    {"value": "new_follower", "label": "New Followers", "icon": "person_add"},
    {"value": "unfollow", "label": "Unfollows", "icon": "person_remove"},
    {
      "value": "mutual_connection",
      "label": "Mutual Connections",
      "icon": "people",
    },
    {"value": "milestone", "label": "Milestones", "icon": "emoji_events"},
    {"value": "system", "label": "System Updates", "icon": "info"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter;
    _showUnreadOnly = widget.showUnreadOnly;
  }

  void _applyFilters() {
    HapticFeedback.lightImpact();
    widget.onFilterChanged(_selectedFilter, _showUnreadOnly);
    Navigator.pop(context);
  }

  void _clearFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFilter = 'all';
      _showUnreadOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),

            // Filter options
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unread only toggle
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'mark_email_unread',
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              'Show unread only',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Switch(
                            value: _showUnreadOnly,
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _showUnreadOnly = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Notification Type',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(height: 1.h),

                    // Filter type options
                    ...(_filterOptions.map((option) {
                      final isSelected = _selectedFilter == option["value"];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFilter = option["value"] as String;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                CustomIconWidget(
                                  iconName: option["icon"] as String,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Text(
                                    option["label"] as String,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  CustomIconWidget(
                                    iconName: 'check_circle',
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
            ),

            // Apply button
            Padding(
              padding: EdgeInsets.all(4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
