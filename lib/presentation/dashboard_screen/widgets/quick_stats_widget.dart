import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Quick stats widget with sparkline charts
/// Displays weekly/monthly trends in compact format
class QuickStatsWidget extends StatelessWidget {
  final List<double> weeklyFollowers;
  final List<double> weeklyUnfollows;

  const QuickStatsWidget({
    super.key,
    required this.weeklyFollowers,
    required this.weeklyUnfollows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Trends',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Followers Trend Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Follower Growth',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '+4.3K',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.successLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successLight.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'arrow_upward',
                                    color: AppTheme.successLight,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '52.3%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.successLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: Semantics(
                    label:
                        'Weekly follower growth sparkline chart showing upward trend',
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: weeklyFollowers.isEmpty
                            ? 1
                            : (weeklyFollowers.length - 1).toDouble(),
                        minY: weeklyFollowers.isEmpty
                            ? 0
                            : weeklyFollowers.reduce((a, b) => a < b ? a : b) -
                                  1,
                        maxY: weeklyFollowers.isEmpty
                            ? 1
                            : weeklyFollowers.reduce((a, b) => a > b ? a : b) +
                                  1,
                        lineBarsData: [
                          LineChartBarData(
                            spots: weeklyFollowers.isEmpty
                                ? [const FlSpot(0, 0)]
                                : List.generate(
                                    weeklyFollowers.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      weeklyFollowers[index],
                                    ),
                                  ),
                            isCurved: true,
                            color: AppTheme.successLight,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.successLight.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last 7 days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Unfollows Trend Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unfollow Rate',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '-71',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.successLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successLight.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'arrow_downward',
                                    color: AppTheme.successLight,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '80%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.successLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: Semantics(
                    label:
                        'Weekly unfollow rate sparkline chart showing downward trend',
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: weeklyUnfollows.isEmpty
                            ? 1
                            : (weeklyUnfollows.length - 1).toDouble(),
                        minY: weeklyUnfollows.isEmpty
                            ? 0
                            : weeklyUnfollows.reduce((a, b) => a < b ? a : b) -
                                  1,
                        maxY: weeklyUnfollows.isEmpty
                            ? 1
                            : weeklyUnfollows.reduce((a, b) => a > b ? a : b) +
                                  1,
                        lineBarsData: [
                          LineChartBarData(
                            spots: weeklyUnfollows.isEmpty
                                ? [const FlSpot(0, 0)]
                                : List.generate(
                                    weeklyUnfollows.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      weeklyUnfollows[index],
                                    ),
                                  ),
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last 7 days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
