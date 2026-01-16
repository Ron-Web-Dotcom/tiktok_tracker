import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Follower growth chart widget with interactive touch support
/// Displays follower growth trends over selected time period
class FollowerGrowthChartWidget extends StatefulWidget {
  final List<dynamic> data;
  final String period;
  final bool isComparisonMode;
  final List<dynamic>? comparisonData;

  const FollowerGrowthChartWidget({
    super.key,
    required this.data,
    required this.period,
    this.isComparisonMode = false,
    this.comparisonData,
  });

  @override
  State<FollowerGrowthChartWidget> createState() =>
      _FollowerGrowthChartWidgetState();
}

class _FollowerGrowthChartWidgetState extends State<FollowerGrowthChartWidget> {
  int? _touchedIndex;

  String _getPeriodLabel(int index) {
    switch (widget.period) {
      case 'week':
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return index < days.length ? days[index] : '';
      case 'month':
        return 'W${index + 1}';
      case 'year':
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return index < months.length ? months[index] : '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                iconName: 'trending_up',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Follower Growth',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_touchedIndex != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.data[_touchedIndex!]}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 30.h,
            child: Semantics(
              label:
                  'Follower Growth Line Chart showing ${widget.period}ly trends',
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: widget.period == 'year' ? 500 : 50,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < widget.data.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Text(
                                _getPeriodLabel(index),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: widget.period == 'year' ? 500 : 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: widget.data.isEmpty
                      ? 1
                      : (widget.data.length - 1).toDouble(),
                  minY: 0,
                  maxY: widget.data.isEmpty
                      ? 1
                      : (widget.data.reduce((a, b) => a > b ? a : b) * 1.2)
                            .toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: widget.data.isEmpty
                          ? [const FlSpot(0, 0)]
                          : List.generate(
                              widget.data.length,
                              (index) => FlSpot(
                                index.toDouble(),
                                (widget.data[index] as num).toDouble(),
                              ),
                            ),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: _touchedIndex == index ? 6 : 4,
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    if (widget.isComparisonMode &&
                        widget.comparisonData != null &&
                        widget.comparisonData!.isNotEmpty)
                      LineChartBarData(
                        spots: List.generate(
                          widget.comparisonData!.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            (widget.comparisonData![index] as num).toDouble(),
                          ),
                        ),
                        isCurved: true,
                        color: theme.colorScheme.secondary,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5],
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? touchResponse) {
                          if (event is FlTapUpEvent || event is FlPanEndEvent) {
                            setState(() => _touchedIndex = null);
                          } else if (touchResponse != null &&
                              touchResponse.lineBarSpots != null) {
                            final spot = touchResponse.lineBarSpots!.first;
                            if (_touchedIndex != spot.spotIndex) {
                              HapticFeedback.lightImpact();
                              setState(() => _touchedIndex = spot.spotIndex);
                            }
                          }
                        },
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.surface,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          return LineTooltipItem(
                            '${barSpot.y.toInt()} followers\n${_getPeriodLabel(barSpot.x.toInt())}',
                            theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
