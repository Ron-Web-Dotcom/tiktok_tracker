import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Filter bottom sheet widget for advanced filtering options
///
/// Features:
/// - Expandable filter categories
/// - Date range picker
/// - Toggle switches for boolean filters
/// - Radio buttons for single-choice filters
/// - Apply and reset buttons
class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> activeFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheetWidget({
    super.key,
    required this.activeFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _tempFilters;
  bool _dateRangeExpanded = false;
  bool _engagementExpanded = false;

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.activeFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _tempFilters.clear());
                  },
                  child: const Text('Reset All'),
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
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mutual followers toggle
                  SwitchListTile(
                    title: Text(
                      'Mutual Followers Only',
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      'Show only followers you follow back',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: _tempFilters['mutualOnly'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        if (value) {
                          _tempFilters['mutualOnly'] = true;
                        } else {
                          _tempFilters.remove('mutualOnly');
                        }
                      });
                    },
                  ),

                  SizedBox(height: 2.h),

                  // Verified only toggle
                  SwitchListTile(
                    title: Text(
                      'Verified Accounts Only',
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      'Show only verified followers',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: _tempFilters['verifiedOnly'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        if (value) {
                          _tempFilters['verifiedOnly'] = true;
                        } else {
                          _tempFilters.remove('verifiedOnly');
                        }
                      });
                    },
                  ),

                  SizedBox(height: 2.h),

                  // Date range filter
                  ExpansionTile(
                    title: Text(
                      'Follow Date Range',
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: _tempFilters.containsKey('dateRange')
                        ? Text(
                            'Custom range selected',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                    initiallyExpanded: _dateRangeExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() => _dateRangeExpanded = expanded);
                    },
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final DateTimeRange?
                                picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  initialDateRange:
                                      _tempFilters.containsKey('dateRange')
                                      ? DateTimeRange(
                                          start:
                                              _tempFilters['dateRange']['start']
                                                  as DateTime,
                                          end:
                                              _tempFilters['dateRange']['end']
                                                  as DateTime,
                                        )
                                      : null,
                                );
                                if (picked != null) {
                                  setState(() {
                                    _tempFilters['dateRange'] = {
                                      'start': picked.start,
                                      'end': picked.end,
                                    };
                                  });
                                }
                              },
                              icon: CustomIconWidget(
                                iconName: Icons.calendar_today.codePoint
                                    .toString(),
                                color: theme.colorScheme.onPrimary,
                                size: 20,
                              ),
                              label: const Text('Select Date Range'),
                            ),
                            if (_tempFilters.containsKey('dateRange'))
                              TextButton(
                                onPressed: () {
                                  setState(
                                    () => _tempFilters.remove('dateRange'),
                                  );
                                },
                                child: const Text('Clear Date Range'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // Engagement level filter
                  ExpansionTile(
                    title: Text(
                      'Engagement Level',
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: _tempFilters.containsKey('engagementLevel')
                        ? Text(
                            (_tempFilters['engagementLevel'] as String)
                                .toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                    initiallyExpanded: _engagementExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() => _engagementExpanded = expanded);
                    },
                    children: [
                      RadioListTile<String>(
                        title: const Text('High Engagement'),
                        value: 'high',
                        groupValue: _tempFilters['engagementLevel'] as String?,
                        onChanged: (value) {
                          setState(
                            () => _tempFilters['engagementLevel'] = value,
                          );
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Medium Engagement'),
                        value: 'medium',
                        groupValue: _tempFilters['engagementLevel'] as String?,
                        onChanged: (value) {
                          setState(
                            () => _tempFilters['engagementLevel'] = value,
                          );
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Low Engagement'),
                        value: 'low',
                        groupValue: _tempFilters['engagementLevel'] as String?,
                        onChanged: (value) {
                          setState(
                            () => _tempFilters['engagementLevel'] = value,
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          setState(
                            () => _tempFilters.remove('engagementLevel'),
                          );
                        },
                        child: const Text('Clear Selection'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilters(_tempFilters);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
