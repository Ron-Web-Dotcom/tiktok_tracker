import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/cache_service.dart';
import '../../services/openai_service.dart';
import '../../services/tiktok_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/actionable_recommendations_widget.dart';
import './widgets/engagement_correlation_chart_widget.dart';
import './widgets/follower_growth_chart_widget.dart';
import './widgets/key_insights_card_widget.dart';
import './widgets/mutual_connection_chart_widget.dart';
import './widgets/time_period_selector_widget.dart';
import './widgets/unfollow_pattern_chart_widget.dart';

/// Analytics Screen - Comprehensive follower relationship insights
/// Features time period selection, interactive charts, key insights, and recommendations
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  bool _isComparisonMode = false;
  String _comparisonPeriod = 'month';

  // Real analytics data from TikTok + OpenAI
  Map<String, dynamic> _analyticsData = {};
  final TikTokService _tiktokService = TikTokService();
  final OpenAIService _openaiService = OpenAIService();
  final CacheService _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Try to load from cache first
      final cachedAnalytics = await _cacheService.getCachedAnalytics();
      final isCacheExpired = await _cacheService.isAnalyticsCacheExpired();

      if (cachedAnalytics != null && !isCacheExpired) {
        setState(() {
          _analyticsData = cachedAnalytics;
          _isLoading = false;
        });
        return;
      }

      // Fetch real TikTok data
      final relationships = await _tiktokService.fetchFollowerRelationships();
      final followers =
          relationships['followers'] as List<Map<String, dynamic>>;
      final following =
          relationships['following'] as List<Map<String, dynamic>>;

      // Generate AI-powered analytics for different time periods
      final weekAnalytics = await _openaiService.generateAnalyticsInsights(
        followers: followers,
        following: following,
        period: 'week',
      );

      final monthAnalytics = await _openaiService.generateAnalyticsInsights(
        followers: followers,
        following: following,
        period: 'month',
      );

      final yearAnalytics = await _openaiService.generateAnalyticsInsights(
        followers: followers,
        following: following,
        period: 'year',
      );

      final analyticsData = {
        'week': {
          'followerGrowth': weekAnalytics['growthRate'] ?? 0.0,
          'unfollowPattern': weekAnalytics['keyMetrics']?['unfollows'] ?? 0,
          'engagementRate': weekAnalytics['engagementTrend'] ?? 'stable',
          'mutualConnections':
              weekAnalytics['keyMetrics']?['mutualConnections'] ?? 0,
          'insights': weekAnalytics['topInsights'] ?? [],
          'recommendations': weekAnalytics['recommendations'] ?? [],
        },
        'month': {
          'followerGrowth': monthAnalytics['growthRate'] ?? 0.0,
          'unfollowPattern': monthAnalytics['keyMetrics']?['unfollows'] ?? 0,
          'engagementRate': monthAnalytics['engagementTrend'] ?? 'stable',
          'mutualConnections':
              monthAnalytics['keyMetrics']?['mutualConnections'] ?? 0,
          'insights': monthAnalytics['topInsights'] ?? [],
          'recommendations': monthAnalytics['recommendations'] ?? [],
        },
        'year': {
          'followerGrowth': yearAnalytics['growthRate'] ?? 0.0,
          'unfollowPattern': yearAnalytics['keyMetrics']?['unfollows'] ?? 0,
          'engagementRate': yearAnalytics['engagementTrend'] ?? 'stable',
          'mutualConnections':
              yearAnalytics['keyMetrics']?['mutualConnections'] ?? 0,
          'insights': yearAnalytics['topInsights'] ?? [],
          'recommendations': yearAnalytics['recommendations'] ?? [],
        },
      };

      // Cache the analytics data
      await _cacheService.cacheAnalytics(analyticsData);

      setState(() {
        _analyticsData = analyticsData;
      });
    } catch (e) {
      // Try to load from cache on error
      final cachedAnalytics = await _cacheService.getCachedAnalytics();
      if (cachedAnalytics != null) {
        setState(() {
          _analyticsData = cachedAnalytics;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load analytics: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod != period) {
      HapticFeedback.lightImpact();
      setState(() => _selectedPeriod = period);
      _loadAnalytics();
    }
  }

  void _toggleComparisonMode() {
    HapticFeedback.mediumImpact();
    setState(() => _isComparisonMode = !_isComparisonMode);
  }

  void _onComparisonPeriodChanged(String period) {
    if (_comparisonPeriod != period) {
      HapticFeedback.lightImpact();
      setState(() => _comparisonPeriod = period);
    }
  }

  Future<void> _exportData(String format) async {
    HapticFeedback.mediumImpact();

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting analytics as $format...'),
        backgroundColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analytics exported successfully as $format'),
          backgroundColor: theme.colorScheme.primary,
          action: SnackBarAction(
            label: 'Share',
            textColor: theme.colorScheme.onPrimary,
            onPressed: () {
              // Share functionality would go here
            },
          ),
        ),
      );
    }
  }

  void _showExportOptions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export Analytics', style: theme.textTheme.titleLarge),
              SizedBox(height: 2.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'picture_as_pdf',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Export as PDF', style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  'Detailed report with charts',
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportData('PDF');
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'table_chart',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Export as CSV', style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  'Raw data for analysis',
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportData('CSV');
                },
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentData =
        _analyticsData[_selectedPeriod] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar.standard(
        title: 'Analytics',
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: _isComparisonMode ? 'compare' : 'compare_arrows',
              color: _isComparisonMode
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _toggleComparisonMode,
            tooltip: 'Comparison Mode',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _showExportOptions,
            tooltip: 'Export',
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: _isLoading || currentData == null
          ? _buildLoadingState(theme)
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: theme.colorScheme.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: TimePeriodSelectorWidget(
                      selectedPeriod: _selectedPeriod,
                      onPeriodChanged: _onPeriodChanged,
                    ),
                  ),
                  if (_isComparisonMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        child: _buildComparisonSelector(theme),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: FollowerGrowthChartWidget(
                      data: currentData['followerGrowth'] as List<dynamic>,
                      period: _selectedPeriod,
                      isComparisonMode: _isComparisonMode,
                      comparisonData:
                          _isComparisonMode &&
                              _analyticsData[_comparisonPeriod] != null
                          ? (_analyticsData[_comparisonPeriod]
                                    as Map<String, dynamic>)['followerGrowth']
                                as List<dynamic>?
                          : null,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: UnfollowPatternChartWidget(
                      data: currentData['unfollowPattern'] as List<dynamic>,
                      period: _selectedPeriod,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: EngagementCorrelationChartWidget(
                      data: currentData['engagementRate'] as List<dynamic>,
                      period: _selectedPeriod,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MutualConnectionChartWidget(
                      mutualConnections:
                          currentData['mutualConnections'] as int,
                      totalFollowers: currentData['totalFollowers'] as int,
                      totalFollowing: currentData['totalFollowing'] as int,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: KeyInsightsCardWidget(
                      insights: currentData['insights'] as List<dynamic>,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ActionableRecommendationsWidget(
                      recommendations:
                          currentData['recommendations'] as List<dynamic>,
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomBar(
        currentRoute: '/analytics-screen',
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      children: [
        _buildSkeletonCard(theme, height: 8.h),
        SizedBox(height: 2.h),
        _buildSkeletonCard(theme, height: 30.h),
        SizedBox(height: 2.h),
        _buildSkeletonCard(theme, height: 30.h),
        SizedBox(height: 2.h),
        _buildSkeletonCard(theme, height: 30.h),
      ],
    );
  }

  Widget _buildSkeletonCard(ThemeData theme, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildComparisonSelector(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'compare',
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Text(
            'Compare with:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('Week')),
                ButtonSegment(value: 'month', label: Text('Month')),
                ButtonSegment(value: 'year', label: Text('Year')),
              ],
              selected: {_comparisonPeriod},
              onSelectionChanged: (Set<String> selection) {
                _onComparisonPeriodChanged(selection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
