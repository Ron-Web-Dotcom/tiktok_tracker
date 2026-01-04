import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Filter bottom sheet widget for following list filtering options
class FilterBottomSheetWidget extends StatelessWidget {
  final String activeFilter;
  final Function(String) onFilterSelected;

  const FilterBottomSheetWidget({
    super.key,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  static const List<Map<String, dynamic>> _filterOptions = [
    {
      "id": "All",
      "label": "All Following",
      "icon": "people",
      "description": "Show all accounts you follow",
    },
    {
      "id": "Not Following Back",
      "label": "Not Following Back",
      "icon": "person_remove",
      "description": "Accounts that don't follow you back",
    },
    {
      "id": "High Engagement",
      "label": "High Engagement",
      "icon": "trending_up",
      "description": "Accounts with engagement score ≥ 70",
    },
    {
      "id": "Low Engagement",
      "label": "Low Engagement",
      "icon": "trending_down",
      "description": "Accounts with engagement score < 50",
    },
    {
      "id": "Inactive",
      "label": "Inactive Accounts",
      "icon": "schedule",
      "description": "Accounts with no recent activity",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.symmetric(vertical: 1.h),
              width: 40,
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
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Text(
                    'Filter Following',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (activeFilter != 'All')
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onFilterSelected('All');
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.colorScheme.outline),

            // Filter Options
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                final isSelected = activeFilter == option["id"];

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: option["icon"] as String,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    option["label"] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    option["description"] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: isSelected
                      ? CustomIconWidget(
                          iconName: 'check_circle',
                          color: theme.colorScheme.primary,
                          size: 24,
                        )
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onFilterSelected(option["id"] as String);
                  },
                );
              },
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
