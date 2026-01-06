import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Analytics section widget displaying visitor trends and insights
///
/// Features:
/// - Key metrics (total visitors, follower conversion rate)
/// - Peak viewing times
/// - Visitor trends
class AnalyticsSectionWidget extends StatelessWidget {
  final Map<String, dynamic> analyticsData;

  const AnalyticsSectionWidget({super.key, required this.analyticsData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVisitors = analyticsData['totalVisitors'] as int? ?? 0;
    final followerConversionRate =
        analyticsData['followerConversionRate'] as double? ?? 0.0;
    final peakViewingTime =
        analyticsData['peakViewingTime'] as String? ?? 'N/A';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, size: 20, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Text(
                'Visitor Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Total Visitors',
                  totalVisitors.toString(),
                  Icons.people,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Conversion Rate',
                  '${followerConversionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInsightRow(
            context,
            'Peak Viewing Time',
            peakViewingTime,
            Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
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

  Widget _buildInsightRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
