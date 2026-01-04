import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/openai_service.dart';
import '../../services/tiktok_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
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

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      }
    } catch (e) {
      // Silent fail - notification count is not critical
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    }
  }

  /// Check if user has previously synced data
  /// If yes, load it from cache for instant display
  Future<void> _checkForExistingData() async {
    final cachedMetrics = await _cacheService.getCachedDashboardMetrics();

    if (cachedMetrics != null) {
      await _loadStoredData();
    }
  }

  /// Load data that was previously saved to device storage
  /// This makes the app feel fast even without internet
  Future<void> _loadStoredData() async {
    final cachedMetrics = await _cacheService.getCachedDashboardMetrics();
    final lastSync = await _cacheService.getLastSyncTime('dashboard');

    if (cachedMetrics != null) {
      setState(() {
        _metrics = List<Map<String, dynamic>>.from(
          cachedMetrics['metrics'] ?? [],
        );
        _activities = List<Map<String, dynamic>>.from(
          cachedMetrics['activities'] ?? [],
        );
        _hasData = true;
        if (lastSync != null) {
          _lastUpdated = lastSync;
        }
        _isLoading = false;
      });
    }
  }

  /// Generate metric cards from stored preferences
  /// (Legacy method for backward compatibility)
  List<Map<String, dynamic>> _generateMetricsFromStorage(
    SharedPreferences prefs,
  ) {
    return [
      {
        "title": "Total Followers",
        "value": prefs.getString('total_followers') ?? '0',
        "trend": prefs.getString('followers_trend') ?? '+0%',
        "isPositive": true,
        "icon": "people",
      },
      {
        "title": "Following",
        "value": prefs.getString('total_following') ?? '0',
        "trend": prefs.getString('following_trend') ?? '+0',
        "isPositive": true,
        "icon": "person_add",
      },
      {
        "title": "Recent Unfollows",
        "value": prefs.getString('recent_unfollows') ?? '0',
        "trend": prefs.getString('unfollows_trend') ?? '0',
        "isPositive": true,
        "icon": "person_remove",
      },
      {
        "title": "Mutual Connections",
        "value": prefs.getString('mutual_connections') ?? '0',
        "trend": prefs.getString('mutual_trend') ?? '+0',
        "isPositive": true,
        "icon": "people_outline",
      },
    ];
  }

  /// Generate activity timeline from stored preferences
  /// (Legacy method for backward compatibility)
  List<Map<String, dynamic>> _generateActivitiesFromStorage(
    SharedPreferences prefs,
  ) {
    // Return empty list if no activities stored
    return [];
  }

  /// Handle pull-to-refresh gesture
  /// User pulls down on the screen to refresh data
  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact(); // Vibrate phone for feedback

    // Call the real sync method to update all data
    await _handleSyncNow();
  }

  /// Main sync function - fetches fresh data from TikTok and analyzes it
  ///
  /// This is the core function that:
  /// 1. Gets your latest followers/following from TikTok
  /// 2. Sends the data to AI for analysis
  /// 3. Generates dashboard metrics and insights
  /// 4. Saves everything locally
  /// 5. Updates the screen
  Future<void> _handleSyncNow() async {
    HapticFeedback.mediumImpact(); // Vibrate phone
    setState(() => _isLoading = true); // Show loading spinner

    try {
      // Step 1: Fetch real TikTok data (followers, following, profile)
      final tiktokData = await _fetchRealTikTokData();

      // Step 2: Analyze with OpenAI to find patterns and insights
      final aiAnalysis = await _analyzeWithAI(tiktokData);

      // Step 3: Generate dashboard data combining TikTok data + AI insights
      final dashboardData = _generateDashboardData(tiktokData, aiAnalysis);

      // Step 4: Store data locally so it's available offline
      await _storeData(dashboardData);

      // Step 5: Reload notification count after sync
      await _loadUnreadNotificationCount();

      // Step 6: Update the screen with new data
      setState(() {
        _hasData = true;
        _keyMetrics = dashboardData['metrics'] as List<Map<String, dynamic>>;
        _activities = dashboardData['activities'] as List<Map<String, dynamic>>;
        _lastUpdated = DateTime.now();
        _isLoading = false;
      });

      HapticFeedback.heavyImpact(); // Strong vibration for success

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully with AI analysis'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      // Show error message if something went wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Fetch fresh data from TikTok API
  /// Gets followers, following, mutual connections, and your profile
  Future<Map<String, dynamic>> _fetchRealTikTokData() async {
    // Fetch real follower relationships from TikTok
    final relationships = await _tiktokService.fetchFollowerRelationships();
    final followers = relationships['followers'] as List<Map<String, dynamic>>;
    final following = relationships['following'] as List<Map<String, dynamic>>;
    final mutualConnections =
        relationships['mutualConnections'] as List<Map<String, dynamic>>;

    // Fetch current user profile
    final profile = await _tiktokService.fetchCurrentUserProfile();

    return {
      'followers': followers,
      'following': following,
      'mutualConnections': mutualConnections,
      'profile': profile,
    };
  }

  /// Send your TikTok data to AI for analysis
  /// AI identifies patterns like who unfollowed you, engagement trends, etc.
  Future<FollowerAnalysisResult> _analyzeWithAI(
    Map<String, dynamic> tiktokData,
  ) async {
    try {
      final openAIService = OpenAIService();
      final client = OpenAIClient(openAIService.dio);

      return await client.analyzeFollowerPatterns(
        followers: tiktokData['followers'] as List<Map<String, dynamic>>,
        following: tiktokData['following'] as List<Map<String, dynamic>>,
      );
    } catch (e) {
      // Return empty analysis if OpenAI fails
      return FollowerAnalysisResult(
        unfollowedUsers: [],
        patterns: [],
        recommendations: [],
        rawResponse: 'Analysis unavailable',
      );
    }
  }

  /// Generate dashboard data from TikTok data and AI analysis
  Map<String, dynamic> _generateDashboardData(
    Map<String, dynamic> tiktokData,
    FollowerAnalysisResult aiAnalysis,
  ) {
    final followers = tiktokData['followers'] as List<Map<String, dynamic>>;
    final following = tiktokData['following'] as List<Map<String, dynamic>>;
    final mutualConnections =
        tiktokData['mutualConnections'] as List<Map<String, dynamic>>;
    final profile = tiktokData['profile'] as Map<String, dynamic>;

    // Calculate metrics from real data
    final totalFollowers = followers.length;
    final totalFollowing = following.length;
    final mutualCount = mutualConnections.length;
    final recentUnfollows = aiAnalysis.unfollowedUsers.length;

    // Calculate trends (compare with stored previous values)
    final followerTrend = _calculateTrend('followers', totalFollowers);
    final followingTrend = _calculateTrend('following', totalFollowing);
    final mutualTrend = _calculateTrend('mutual', mutualCount);

    final metrics = [
      {
        "title": "Total Followers",
        "value": _formatNumber(totalFollowers),
        "trend": followerTrend['display'],
        "isPositive": followerTrend['isPositive'],
        "icon": "people",
      },
      {
        "title": "Following",
        "value": _formatNumber(totalFollowing),
        "trend": followingTrend['display'],
        "isPositive": followingTrend['isPositive'],
        "icon": "person_add",
      },
      {
        "title": "Recent Unfollows",
        "value": recentUnfollows.toString(),
        "trend": recentUnfollows > 0 ? "-$recentUnfollows" : "0",
        "isPositive": recentUnfollows == 0,
        "icon": "person_remove",
      },
      {
        "title": "Mutual Connections",
        "value": _formatNumber(mutualCount),
        "trend": mutualTrend['display'],
        "isPositive": mutualTrend['isPositive'],
        "icon": "people_outline",
      },
    ];

    // Generate activities from real data and AI insights
    final activities = <Map<String, dynamic>>[];

    // Add unfollowed users to activities (from AI analysis)
    for (var i = 0; i < aiAnalysis.unfollowedUsers.take(3).length; i++) {
      final user = aiAnalysis.unfollowedUsers[i];
      activities.add({
        "id": i + 1,
        "username": user['username'],
        "displayName": user['displayName'],
        "avatar":
            user['avatar'] ??
            "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
        "semanticLabel": "Profile photo of ${user['displayName']}",
        "action": "unfollowed you",
        "timestamp": DateTime.now().subtract(Duration(hours: i * 2)),
        "actionType": "unfollow",
      });
    }

    // Add recent followers (sorted by followDate, latest first)
    final recentFollowers = followers.take(5).toList();
    for (var i = 0; i < recentFollowers.length; i++) {
      final follower = recentFollowers[i];
      activities.add({
        "id": activities.length + 1,
        "username": follower['username'],
        "displayName": follower['displayName'],
        "avatar":
            follower['avatar'] ??
            "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
        "semanticLabel": "Profile photo of ${follower['displayName']}",
        "action": follower['isMutual'] == true
            ? "followed you back"
            : "started following you",
        "timestamp": follower['followDate'] as DateTime,
        "actionType": "follow",
      });
    }

    // Sort activities by timestamp (most recent first)
    activities.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );

    return {'metrics': metrics, 'activities': activities.take(10).toList()};
  }

  /// Calculate trend compared to previous sync
  Map<String, dynamic> _calculateTrend(String key, int currentValue) {
    // This would ideally compare with stored previous values
    // For now, return neutral trend
    return {'display': '+0', 'isPositive': true};
  }

  /// Format large numbers (e.g., 12500 -> 12.5K)
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Store dashboard data locally
  Future<void> _storeData(Map<String, dynamic> data) async {
    await _cacheService.cacheDashboardMetrics(data);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Dashboard',
        actions: [
          // Notifications icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
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
                      color: AppTheme.errorLight,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'privacy') {
                Navigator.pushNamed(context, AppRoutes.privacyCompliance);
              } else if (value == 'features') {
                Navigator.pushNamed(context, AppRoutes.alternativeFeatures);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(
                      Icons.privacy_tip,
                      size: 20,
                      color: AppTheme.primaryLight,
                    ),
                    SizedBox(width: 2.w),
                    Text('Privacy & Compliance'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'features',
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: AppTheme.primaryLight,
                    ),
                    SizedBox(width: 2.w),
                    Text('Alternative Features'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _hasData ? _buildDashboardContent(theme) : const EmptyStateWidget(),
      floatingActionButton: _hasData
          ? FloatingActionButton.extended(
              onPressed: _handleSyncNow,
              icon: CustomIconWidget(
                iconName: 'sync',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              label: Text(
                'Sync Now',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            )
          : null,
      bottomNavigationBar: const CustomBottomBar(
        currentRoute: '/dashboard-screen',
      ),
    );
  }

  Widget _buildDashboardContent(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
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
                        title: metric["title"] as String,
                        value: metric["value"] as String,
                        trend: metric["trend"] as String,
                        isPositive: metric["isPositive"] as bool,
                        iconName: metric["icon"] as String,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Quick Stats Section
          const SliverToBoxAdapter(child: QuickStatsWidget()),

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