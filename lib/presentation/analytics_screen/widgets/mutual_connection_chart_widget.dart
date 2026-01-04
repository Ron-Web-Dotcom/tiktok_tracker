import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Mutual connection chart widget with pie chart visualization
/// Shows distribution of mutual connections, followers only, and following only
class MutualConnectionChartWidget extends StatefulWidget {
  final int mutualConnections;
  final int totalFollowers;
  final int totalFollowing;

  const MutualConnectionChartWidget({
    super.key,
    required this.mutualConnections,
    required this.totalFollowers,
    required this.totalFollowing,
  });

  @override
  State<MutualConnectionChartWidget> createState() =>
      _MutualConnectionChartWidgetState();
}

class _MutualConnectionChartWidgetState
    extends State<MutualConnectionChartWidget> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final followersOnly = widget.totalFollowers - widget.mutualConnections;
    final followingOnly = widget.totalFollowing - widget.mutualConnections;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'people',
                color: theme.colorScheme.tertiary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Connection Analysis',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 30.h,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Semantics(
                    label:
                        'Connection Distribution Pie Chart showing mutual connections, followers only, and following only',
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (
                                FlTouchEvent event,
                                PieTouchResponse? pieTouchResponse,
                              ) {
                                if (event is FlTapUpEvent ||
                                    event is FlPanEndEvent) {
                                  setState(() => _touchedIndex = null);
                                } else if (pieTouchResponse != null &&
                                    pieTouchResponse.touchedSection != null) {
                                  final index = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                  if (_touchedIndex != index) {
                                    HapticFeedback.lightImpact();
                                    setState(() => _touchedIndex = index);
                                  }
                                }
                              },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: theme.colorScheme.primary,
                            value: widget.mutualConnections.toDouble(),
                            title: _touchedIndex == 0
                                ? '${widget.mutualConnections}'
                                : '',
                            radius: _touchedIndex == 0 ? 60 : 50,
                            titleStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          PieChartSectionData(
                            color: theme.colorScheme.secondary,
                            value: followersOnly.toDouble(),
                            title: _touchedIndex == 1 ? '$followersOnly' : '',
                            radius: _touchedIndex == 1 ? 60 : 50,
                            titleStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          PieChartSectionData(
                            color: theme.colorScheme.tertiary,
                            value: followingOnly.toDouble(),
                            title: _touchedIndex == 2 ? '$followingOnly' : '',
                            radius: _touchedIndex == 2 ? 60 : 50,
                            titleStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        theme,
                        color: theme.colorScheme.primary,
                        label: 'Mutual',
                        value: widget.mutualConnections,
                      ),
                      SizedBox(height: 2.h),
                      _buildLegendItem(
                        theme,
                        color: theme.colorScheme.secondary,
                        label: 'Followers',
                        value: followersOnly,
                      ),
                      SizedBox(height: 2.h),
                      _buildLegendItem(
                        theme,
                        color: theme.colorScheme.tertiary,
                        label: 'Following',
                        value: followingOnly,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    ThemeData theme, {
    required Color color,
    required String label,
    required int value,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 2.w),
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
              Text(
                value.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
