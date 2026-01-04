import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/openai_service.dart';
import '../../services/tiktok_service.dart';
import './widgets/notification_card_widget.dart';
import './widgets/notification_filter_sheet_widget.dart';
import './widgets/ai_insights_card_widget.dart';

/// Notifications Screen - Centralizes all follower activity alerts and app updates
///
/// Features:
/// - Chronological notification list with intelligent categorization
/// - Pull-to-refresh for latest notifications
/// - Swipe gestures for quick actions (mark read/delete)
/// - Filter options by type, date, and importance
/// - Batch selection mode for mass actions
/// - Deep linking to relevant profiles/content
/// - Platform-specific styling and interactions
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Notification filter state
  String _selectedFilter = 'all';
  bool _showUnreadOnly = false;
  bool _batchSelectionMode = false;
  final Set<int> _selectedNotifications = {};

  // AI Analysis state
  bool _isAnalyzing = false;
  FollowerAnalysisResult? _analysisResult;
  String? _analysisError;

  // Real notifications data from TikTok
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TikTokService _tiktokService = TikTokService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Load notifications from TikTok service
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = await _tiktokService.fetchNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    var filtered = _notifications;

    // Filter by read status
    if (_showUnreadOnly) {
      filtered = filtered.where((n) => !(n["isRead"] as bool)).toList();
    }

    // Filter by type
    if (_selectedFilter != 'all') {
      filtered = filtered.where((n) => n["type"] == _selectedFilter).toList();
    }

    return filtered;
  }

  int get _unreadCount =>
      _notifications.where((n) => !(n["isRead"] as bool)).length;

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _loadNotifications();
  }

  void _markAsRead(int notificationId) async {
    HapticFeedback.lightImpact();
    setState(() {
      final index = _notifications.indexWhere((n) => n["id"] == notificationId);
      if (index != -1) {
        _notifications[index]["isRead"] = true;
      }
    });

    // Update in storage
    await _tiktokService.markNotificationAsRead(notificationId);
  }

  void _deleteNotification(int notificationId) async {
    HapticFeedback.mediumImpact();
    final notification = _notifications.firstWhere(
      (n) => n["id"] == notificationId,
    );
    setState(() {
      _notifications.removeWhere((n) => n["id"] == notificationId);
    });

    // Delete from storage
    await _tiktokService.deleteNotification(notificationId);

    // Show undo snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                _notifications.insert(0, notification);
              });
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationFilterSheetWidget(
        selectedFilter: _selectedFilter,
        showUnreadOnly: _showUnreadOnly,
        onFilterChanged: (filter, unreadOnly) {
          setState(() {
            _selectedFilter = filter;
            _showUnreadOnly = unreadOnly;
          });
        },
      ),
    );
  }

  void _toggleBatchSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      _batchSelectionMode = !_batchSelectionMode;
      if (!_batchSelectionMode) {
        _selectedNotifications.clear();
      }
    });
  }

  void _toggleNotificationSelection(int notificationId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
      } else {
        _selectedNotifications.add(notificationId);
      }
    });
  }

  Future<void> _analyzeFollowerPatterns() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      // Get mock data from followers and following screens
      final followers = _getMockFollowers();
      final following = _getMockFollowing();

      // Initialize OpenAI client
      final openAIService = OpenAIService();
      final client = OpenAIClient(openAIService.dio);

      // Analyze patterns
      final result = await client.analyzeFollowerPatterns(
        followers: followers,
        following: following,
      );

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI analysis complete! Check insights below.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getMockFollowers() {
    return [
      {
        "id": "1",
        "username": "@sarah_creates",
        "displayName": "Sarah Johnson",
        "profileImage":
            "https://images.unsplash.com/photo-1681779279774-79d871470b6f",
        "followDate": DateTime.now().subtract(const Duration(days: 2)),
        "isMutual": true,
        "isVerified": true,
        "engagementLevel": "high",
        "followerCount": 125000,
        "bio": "Content creator | Travel enthusiast",
      },
      {
        "id": "2",
        "username": "@mike_fitness",
        "displayName": "Mike Thompson",
        "profileImage":
            "https://img.rocket.new/generatedImages/rocket_gen_img_17f9ba51f-1763294104164.png",
        "followDate": DateTime.now().subtract(const Duration(days: 5)),
        "isMutual": false,
        "isVerified": false,
        "engagementLevel": "medium",
        "followerCount": 45000,
        "bio": "Fitness coach | Nutrition expert",
      },
      {
        "id": "3",
        "username": "@emma_art",
        "displayName": "Emma Wilson",
        "profileImage":
            "https://images.unsplash.com/photo-1681838514810-be92d337bd55",
        "followDate": DateTime.now().subtract(const Duration(days: 10)),
        "isMutual": true,
        "isVerified": true,
        "engagementLevel": "high",
        "followerCount": 89000,
        "bio": "Digital artist | Illustrator",
      },
    ];
  }

  List<Map<String, dynamic>> _getMockFollowing() {
    return [
      {
        "id": 1,
        "username": "@sarah_creates",
        "displayName": "Sarah Johnson",
        "avatar":
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400",
        "followsBack": true,
        "lastInteraction": DateTime.now().subtract(const Duration(hours: 3)),
        "engagementScore": 85,
        "contentCategory": "Lifestyle",
        "followDate": DateTime.now().subtract(const Duration(days: 45)),
        "mutualConnections": 12,
        "isActive": true,
      },
      {
        "id": 2,
        "username": "@tech_guru_mike",
        "displayName": "Michael Chen",
        "avatar":
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400",
        "followsBack": false,
        "lastInteraction": DateTime.now().subtract(const Duration(days: 15)),
        "engagementScore": 45,
        "contentCategory": "Technology",
        "followDate": DateTime.now().subtract(const Duration(days: 120)),
        "mutualConnections": 3,
        "isActive": true,
      },
      {
        "id": 4,
        "username": "@foodie_alex",
        "displayName": "Alex Thompson",
        "avatar":
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400",
        "followsBack": false,
        "lastInteraction": DateTime.now().subtract(const Duration(days: 30)),
        "engagementScore": 38,
        "contentCategory": "Food",
        "followDate": DateTime.now().subtract(const Duration(days: 180)),
        "mutualConnections": 1,
        "isActive": false,
      },
    ];
  }

  void _markAllAsRead() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (var id in _selectedNotifications) {
        final index = _notifications.indexWhere((n) => n["id"] == id);
        if (index != -1) {
          _notifications[index]["isRead"] = true;
        }
      }
      _selectedNotifications.clear();
      _batchSelectionMode = false;
    });
  }

  void _deleteSelected() {
    HapticFeedback.mediumImpact();
    final selectedIds = List<int>.from(_selectedNotifications);
    setState(() {
      _notifications.removeWhere((n) => selectedIds.contains(n["id"]));
      _selectedNotifications.clear();
      _batchSelectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedIds.length} notifications deleted'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    HapticFeedback.lightImpact();

    // Mark as read
    _markAsRead(notification["id"] as int);

    // Navigate based on notification type
    if (notification["actionable"] == true && notification["userId"] != null) {
      Navigator.pushNamed(
        context,
        '/profile-detail-screen',
        arguments: {'userId': notification["userId"]},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredNotifications = _filteredNotifications;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          if (_unreadCount > 0)
            Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_unreadCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: theme.colorScheme.onSurface,
            ),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: _batchSelectionMode ? 'close' : 'checklist',
              color: theme.colorScheme.onSurface,
            ),
            onPressed: _toggleBatchSelection,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState(theme)
          : _errorMessage != null
          ? _buildErrorState(theme)
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: filteredNotifications.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      itemCount: filteredNotifications.length + 1,
                      itemBuilder: (context, index) {
                        // AI Insights Card at the top
                        if (index == 0) {
                          return Column(
                            children: [
                              _buildAIAnalysisSection(theme),
                              if (_analysisResult != null)
                                AIInsightsCardWidget(
                                  analysisResult: _analysisResult!,
                                  onDismiss: () {
                                    setState(() {
                                      _analysisResult = null;
                                    });
                                  },
                                ),
                              SizedBox(height: 1.h),
                            ],
                          );
                        }

                        final notification = filteredNotifications[index - 1];
                        final notificationId = notification["id"] as int;
                        final isSelected = _selectedNotifications.contains(
                          notificationId,
                        );

                        return NotificationCardWidget(
                          notification: notification,
                          isSelected: isSelected,
                          batchSelectionMode: _batchSelectionMode,
                          onTap: () {
                            if (_batchSelectionMode) {
                              _toggleNotificationSelection(notificationId);
                            } else {
                              _handleNotificationTap(notification);
                            }
                          },
                          onMarkAsRead: () => _markAsRead(notificationId),
                          onDelete: () => _deleteNotification(notificationId),
                        );
                      },
                    ),
            ),
      bottomNavigationBar:
          _batchSelectionMode && _selectedNotifications.isNotEmpty
          ? _buildBatchActionBar(theme)
          : CustomBottomBar(
              currentRoute: '/notifications-screen',
              onNavigate: (route) {
                Navigator.pushNamed(context, route);
              },
            ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          SizedBox(height: 2.h),
          Text(
            'Loading notifications...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'error_outline',
                  color: Colors.red,
                  size: 15.w,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Failed to load notifications',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage ?? 'Please check your connection and try again',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: Text(
                'Retry',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisSection(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'psychology',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Follower Analysis',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Detect who unfollowed despite following back',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeFollowerPatterns,
              icon: _isAnalyzing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : CustomIconWidget(
                      iconName: 'auto_awesome',
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
              label: Text(
                _isAnalyzing ? 'Analyzing...' : 'Analyze Patterns',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (_analysisError != null)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'error',
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Analysis failed. Check API key configuration.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBatchActionBar(ThemeData theme) {
    return CustomBottomBar(
      currentRoute: '/notifications-screen',
      notificationBadgeCount: _unreadCount,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'notifications_none',
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 15.w,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              _showUnreadOnly || _selectedFilter != 'all'
                  ? 'No notifications found'
                  : 'No notifications yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              _showUnreadOnly || _selectedFilter != 'all'
                  ? 'Try adjusting your filters'
                  : 'Stay tuned for follower updates and activity alerts',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_showUnreadOnly && _selectedFilter == 'all') ...[
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Navigate to notification settings
                },
                icon: CustomIconWidget(
                  iconName: 'notifications_active',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: const Text('Enable Notifications'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
