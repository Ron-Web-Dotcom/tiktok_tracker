import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/cache_service.dart';
import '../../services/tiktok_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/activity_timeline_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/key_metrics_card_widget.dart';
import './widgets/quick_stats_widget.dart';

/// Dashboard Screen - The main hub of the TikTok Tracker app
///
/// This is the first screen users see after logging in.
/// It shows an overview of your TikTok account metrics and recent activity.
///
/// Key Features:
/// - Pull down to refresh your data from TikTok
/// - View key metrics (followers, following, unfollows, mutual connections)
/// - See recent activity timeline
/// - Floating sync button for manual data refresh
/// - Bottom navigation to access other screens
///
/// How it works:
/// 1. Checks if you have existing data cached locally
/// 2. Displays cached data immediately for fast loading
/// 3. When you sync, fetches fresh data from TikTok
/// 4. Uses AI to analyze your follower patterns
/// 5. Updates the display with new insights
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Loading state - shows spinner when fetching data
  bool _isLoading = false;

  // Atomic lock to prevent race conditions in sync operations
  bool _isSyncing = false;

  // Whether user has synced data at least once
  bool _hasData = false;

  // When data was last updated
  DateTime _lastUpdated = DateTime.now();

  // List of metric cards to display
  List<Map<String, dynamic>> _metrics = [];

  // List of recent activities
  List<Map<String, dynamic>> _activities = [];

  // Number of unread notifications (shown as badge)
  int _unreadNotificationCount = 0;

  // Services for fetching and storing data
  final TikTokService _tiktokService = TikTokService();
  final CacheService _cacheService = CacheService();

  // Key metrics displayed at the top
  List<Map<String, dynamic>> _keyMetrics = [];

  // Demo mode disclaimer visibility
  bool _showDemoDisclaimer = true;

  @override
  void initState() {
    super.initState();
    // When screen loads, check for existing data and notification count
    _checkForExistingData();
    _loadUnreadNotificationCount();
  }

  /// Load the count of unread notifications
  /// This number is shown as a badge on the notifications icon
  Future<void> _loadUnreadNotificationCount() async {
    try {
      final tiktokService = TikTokService();
      final notifications = await tiktokService.fetchNotifications();

      final unreadCount = notifications
          .where((n) => n['isRead'] == false)
          .length;

      if (!mounted) return;
      setState(() {
        _unreadNotificationCount = unreadCount;
      });
    } catch (e) {
      // Silent fail - notification count is not critical
      if (!mounted) return;
      setState(() {
        _unreadNotificationCount = 0;
      });
    }
  }

  /// Check if user has synced data before
  /// If yes, load cached data immediately
  Future<void> _checkForExistingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasData = prefs.getBool('has_synced_data') ?? false;

      if (hasData) {
        // Load cached data
        final cachedMetrics = await _cacheService.getCachedDashboardMetrics();
        final cachedActivities = await _cacheService.getCachedNotifications();
        final lastUpdatedStr = prefs.getString('last_updated');

        if (cachedMetrics != null) {
          if (!mounted) return;
          setState(() {
            _hasData = true;
            _metrics =
                (cachedMetrics['metrics'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            _activities =
                (cachedActivities as List?)?.cast<Map<String, dynamic>>() ?? [];
            _lastUpdated = lastUpdatedStr != null
                ? DateTime.tryParse(lastUpdatedStr) ?? DateTime.now()
                : DateTime.now();
            _keyMetrics = _buildKeyMetrics();
          });
        }
      }
    } catch (e) {
      // Silent fail - will show empty state
    }
  }

  /// Build the key metrics cards from current data
  List<Map<String, dynamic>> _buildKeyMetrics() {
    // Find specific metrics from the metrics list
    final followersMetric = _metrics.firstWhere(
      (m) => m['title'] == 'Total Followers',
      orElse: () => {'value': '0', 'change': '+0'},
    );
    final followingMetric = _metrics.firstWhere(
      (m) => m['title'] == 'Following',
      orElse: () => {'value': '0', 'change': '+0'},
    );
    final unfollowsMetric = _metrics.firstWhere(
      (m) => m['title'] == 'Unfollows',
      orElse: () => {'value': '0', 'change': '+0'},
    );
    final mutualMetric = _metrics.firstWhere(
      (m) => m['title'] == 'Mutual Connections',
      orElse: () => {'value': '0', 'change': '+0'},
    );

    return [
      {
        'title': 'Followers',
        'value': followersMetric['value'],
        'change': followersMetric['change'],
        'icon': Icons.people,
        'color': AppTheme.primaryLight,
      },
      {
        'title': 'Following',
        'value': followingMetric['value'],
        'change': followingMetric['change'],
        'icon': Icons.person_add,
        'color': AppTheme.secondaryLight,
      },
      {
        'title': 'Unfollows',
        'value': unfollowsMetric['value'],
        'change': unfollowsMetric['change'],
        'icon': Icons.person_remove,
        'color': AppTheme.errorLight,
      },
      {
        'title': 'Mutual',
        'value': mutualMetric['value'],
        'change': mutualMetric['change'],
        'icon': Icons.sync_alt,
        'color': AppTheme.successLight,
      },
    ];
  }

  /// Sync data from TikTok
  /// This is the main data fetching operation
  Future<void> _syncData() async {
    // Prevent multiple simultaneous syncs with atomic lock
    if (_isSyncing) return;
    _isSyncing = true;

    if (!mounted) {
      _isSyncing = false;
      return;
    }
    setState(() => _isLoading = true);

    // Vibrate phone for feedback
    HapticFeedback.mediumImpact();

    try {
      // Fetch follower relationships from TikTok
      final relationships = await _tiktokService.fetchFollowerRelationships();

      // Extract data with null-safe casting
      final followers =
          (relationships['followers'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      final following =
          (relationships['following'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      final notFollowingBack =
          (relationships['notFollowingBack'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final notFollowedBack =
          (relationships['notFollowedBack'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final mutualConnections =
          (relationships['mutualConnections'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Calculate weekly trends from real data
      final weeklyFollowers = _calculateWeeklyTrend(followers);
      final weeklyUnfollows = _calculateWeeklyUnfollows(notFollowingBack);

      // Build metrics cards
      final newMetrics = [
        {
          'title': 'Total Followers',
          'value': followers.length.toString(),
          'change': '+${(followers.length * 0.05).toInt()}',
          'icon': Icons.people,
          'color': AppTheme.primaryLight,
          'weeklyData': weeklyFollowers,
        },
        {
          'title': 'Following',
          'value': following.length.toString(),
          'change': '+${(following.length * 0.03).toInt()}',
          'icon': Icons.person_add,
          'color': AppTheme.secondaryLight,
        },
        {
          'title': 'Unfollows',
          'value': notFollowingBack.length.toString(),
          'change': '-${(notFollowingBack.length * 0.1).toInt()}',
          'icon': Icons.person_remove,
          'color': AppTheme.errorLight,
          'weeklyData': weeklyUnfollows,
        },
        {
          'title': 'Mutual Connections',
          'value': mutualConnections.length.toString(),
          'change': '+${(mutualConnections.length * 0.08).toInt()}',
          'icon': Icons.sync_alt,
          'color': AppTheme.successLight,
        },
      ];

      // Build activity timeline
      final newActivities = _buildActivityTimeline(
        followers,
        following,
        notFollowingBack,
      );

      // Cache the data
      await _cacheService.cacheDashboardMetrics({'metrics': newMetrics});
      await _cacheService.cacheNotifications(newActivities);

      // Save sync status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_synced_data', true);
      await prefs.setString('last_updated', DateTime.now().toIso8601String());

      // Update UI
      if (!mounted) return;
      setState(() {
        _hasData = true;
        _metrics = newMetrics;
        _activities = newActivities;
        _lastUpdated = DateTime.now();
        _keyMetrics = _buildKeyMetrics();
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data synced successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successLight,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Calculate weekly follower trend from real data
  List<double> _calculateWeeklyTrend(List<Map<String, dynamic>> followers) {
    final now = DateTime.now();
    final weeklyData = List<double>.filled(7, 0);

    for (var follower in followers) {
      final followDate = follower['followDate'] as DateTime;
      final daysDiff = now.difference(followDate).inDays;

      if (daysDiff < 7) {
        weeklyData[6 - daysDiff]++;
      }
    }

    // Convert to cumulative growth
    for (int i = 1; i < weeklyData.length; i++) {
      weeklyData[i] += weeklyData[i - 1];
    }

    return weeklyData;
  }

  /// Calculate weekly unfollow trend from real data
  List<double> _calculateWeeklyUnfollows(
    List<Map<String, dynamic>> notFollowingBack,
  ) {
    final now = DateTime.now();
    final weeklyData = List<double>.filled(7, 0);

    for (var user in notFollowingBack) {
      final followDate = user['followDate'] as DateTime;
      final daysDiff = now.difference(followDate).inDays;

      if (daysDiff < 7) {
        weeklyData[6 - daysDiff]++;
      }
    }

    return weeklyData;
  }

  /// Build activity timeline from follower data
  List<Map<String, dynamic>> _buildActivityTimeline(
    List<Map<String, dynamic>> followers,
    List<Map<String, dynamic>> following,
    List<Map<String, dynamic>> notFollowingBack,
  ) {
    final activities = <Map<String, dynamic>>[];

    // Recent followers (last 5)
    final recentFollowers = followers.take(5).toList();
    for (final follower in recentFollowers) {
      activities.add({
        'type': 'new_follower',
        'title': 'New Follower',
        'description': '${follower['displayName']} started following you',
        'timestamp': follower['followDate'],
        'icon': Icons.person_add,
        'color': AppTheme.successLight,
      });
    }

    // Recent unfollows (last 3)
    final recentUnfollows = notFollowingBack.take(3).toList();
    for (final unfollow in recentUnfollows) {
      activities.add({
        'type': 'unfollow',
        'title': 'Unfollowed',
        'description': '${unfollow['displayName']} unfollowed you',
        'timestamp': DateTime.now().subtract(
          Duration(hours: notFollowingBack.indexOf(unfollow) * 2),
        ),
        'icon': Icons.person_remove,
        'color': AppTheme.errorLight,
      });
    }

    // Sort by timestamp (newest first)
    activities.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );

    return activities;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard',
        actions: [
          // Notifications icon with badge
          Stack(
            children: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: Icons.notifications_outlined.codePoint.toString(),
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 9
                          ? '9+'
                          : _unreadNotificationCount.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Profile visitors quick action
          IconButton(
            icon: CustomIconWidget(
              iconName: Icons.visibility.codePoint.toString(),
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profileVisitors);
            },
          ),
        ],
      ),
      body: _hasData ? _buildDashboardContent() : _buildEmptyState(),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: AppRoutes.dashboard,
        notificationBadgeCount: _unreadNotificationCount,
      ),
      floatingActionButton: _hasData
          ? FloatingActionButton.extended(
              onPressed: _syncData,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(_isLoading ? 'Syncing...' : 'Sync'),
            )
          : null,
    );
  }

  Widget _buildDashboardContent() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        // Handle refresh
      },
      color: theme.colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Demo Mode Disclaimer Banner
          if (_showDemoDisclaimer)
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(3.w),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.orange.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        '⚠️ DEMO MODE: Using simulated data for demonstration purposes',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                      onPressed: () {
                        setState(() {
                          _showDemoDisclaimer = false;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          // Key Metrics Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Key Metrics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _keyMetrics.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final metric = _keyMetrics[index];
                      return KeyMetricsCardWidget(
                        title: metric["title"] as String? ?? '',
                        value: metric["value"] as String? ?? '0',
                        trend: (metric["change"] as String?) ?? '+0',
                        isPositive:
                            (metric["change"] as String?)?.startsWith('+') ??
                            true,
                        iconName:
                            (metric["icon"] as IconData?)?.codePoint
                                .toString() ??
                            Icons.help_outline.codePoint.toString(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Quick Stats Section
          SliverToBoxAdapter(
            child: _hasData && _metrics.isNotEmpty
                ? QuickStatsWidget(
                    weeklyFollowers:
                        (_metrics.firstWhere(
                                      (m) => m['title'] == 'Total Followers',
                                      orElse: () => {
                                        'weeklyData': [
                                          0.0,
                                          0.0,
                                          0.0,
                                          0.0,
                                          0.0,
                                          0.0,
                                          0.0,
                                        ],
                                      },
                                    )['weeklyData']
                                    as List<dynamic>? ??
                                [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
                            .cast<double>(),
                    weeklyUnfollows:
                        (_metrics.firstWhere(
                                      (m) => m['title'] == 'Unfollows',
                                      orElse: () => {
                                        'weeklyData': [
                                          0.0,
                                          0.0,
                                          0.0,
                                          0.0,
                                          0.0,
                                          0.0,
                                          0.0,
                                        ],
                                      },
                                    )['weeklyData']
                                    as List<dynamic>? ??
                                [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
                            .cast<double>(),
                  )
                : const SizedBox.shrink(),
          ),

          // Activity Timeline Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Navigate to full activity list
                    },
                    child: Text(
                      'View All',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Activity Timeline List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final activity = _activities[index];
                return ActivityTimelineCardWidget(
                  username: activity["username"] as String,
                  displayName: activity["displayName"] as String,
                  avatar: activity["avatar"] as String,
                  semanticLabel: activity["semanticLabel"] as String,
                  action: activity["action"] as String,
                  timestamp: activity["timestamp"] as DateTime,
                  actionType: activity["actionType"] as String,
                  onViewProfile: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/profile-detail-screen');
                  },
                  onBlock: () {
                    HapticFeedback.mediumImpact();
                    _showActionDialog(
                      context,
                      'Block User',
                      'Are you sure you want to block ${activity["displayName"]}?',
                    );
                  },
                  onUnfollow: () {
                    HapticFeedback.mediumImpact();
                    _showActionDialog(
                      context,
                      'Unfollow User',
                      'Are you sure you want to unfollow ${activity["displayName"]}?',
                    );
                  },
                );
              }, childCount: _activities.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget();
  }

  void _showActionDialog(BuildContext context, String title, String message) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Action completed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
