import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Key Metrics Card Widget - Displays a single metric on the dashboard
///
/// This widget shows one key metric like "Total Followers" or "Following".
/// Each card includes:
/// - An icon representing the metric
/// - The metric value (e.g., "1,234")
/// - A trend indicator (up/down arrow with percentage)
/// - Color coding (green for positive, red for negative)
///
/// Used in the dashboard screen's horizontal scrolling metrics section.
///
/// Example:
/// ```dart
/// KeyMetricsCardWidget(
///   title: 'Total Followers',
///   value: '1,234',
///   trend: '+5.2%',
///   isPositive: true,
///   iconName: 'people',
/// )
/// ```
class KeyMetricsCardWidget extends StatelessWidget {
  /// Title of the metric (e.g., "Total Followers")
  final String title;

  /// Current value of the metric (e.g., "1,234")
  final String value;

  /// Trend text (e.g., "+5.2%" or "-3")
  final String trend;

  /// Whether the trend is positive (green) or negative (red)
  final bool isPositive;

  /// Icon name to display (e.g., "people", "person_add")
  final String iconName;

  const KeyMetricsCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
    required this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160, // Fixed width for horizontal scrolling
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top row: Icon and trend indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon container with background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              // Trend badge (green for up, red for down)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppTheme.successLight.withValues(alpha: 0.1)
                      : AppTheme.errorLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Up or down arrow
                    CustomIconWidget(
                      iconName: isPositive ? 'arrow_upward' : 'arrow_downward',
                      color: isPositive
                          ? AppTheme.successLight
                          : AppTheme.errorLight,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    // Trend percentage/number
                    Text(
                      trend,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isPositive
                            ? AppTheme.successLight
                            : AppTheme.errorLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metric value (large number)
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          // Metric title (small text)
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
