import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Optimized caching service for offline functionality
/// Handles efficient storage and retrieval of follower lists, notifications, and analytics
class CacheService {
  static final CacheService _instance = CacheService._internal();
  SharedPreferences? _prefs;

  // Cache keys
  static const String _followersKey = 'cached_followers';
  static const String _followingKey = 'cached_following';
  static const String _notificationsKey = 'cached_notifications';
  static const String _analyticsKey = 'cached_analytics';
  static const String _dashboardMetricsKey = 'cached_dashboard_metrics';
  static const String _userProfileKey = 'cached_user_profile';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _followerIdsKey = 'cached_follower_ids';
  static const String _followingIdsKey = 'cached_following_ids';

  // Cache expiration times (in hours)
  static const int _followersCacheExpiry = 24;
  static const int _analyticsCacheExpiry = 12;
  static const int _notificationsCacheExpiry = 48;

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  /// Initialize SharedPreferences
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  // ==================== FOLLOWERS CACHING ====================

  /// Cache followers list with compression
  Future<void> cacheFollowers(List<Map<String, dynamic>> followers) async {
    final prefs = await _getPrefs();

    // Store full follower data as JSON
    final followersJson = jsonEncode(followers);
    await prefs.setString(_followersKey, followersJson);

    // Store follower IDs separately for quick comparison
    final followerIds = followers.map((f) => f['id'] as String).toList();
    await prefs.setStringList(_followerIdsKey, followerIds);

    // Update sync timestamp
    await _updateSyncTimestamp('followers');
  }

  /// Retrieve cached followers
  Future<List<Map<String, dynamic>>?> getCachedFollowers() async {
    final prefs = await _getPrefs();
    final followersJson = prefs.getString(_followersKey);

    if (followersJson == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(followersJson);
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        // Restore DateTime objects
        if (map['followDate'] is String) {
          map['followDate'] = DateTime.parse(map['followDate']);
        }
        return map;
      }).toList();
    } catch (e) {
      return null;
    }
  }

  /// Get cached follower IDs only (lightweight)
  Future<List<String>> getCachedFollowerIds() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_followerIdsKey) ?? [];
  }

  // ==================== FOLLOWING CACHING ====================

  /// Cache following list with compression
  Future<void> cacheFollowing(List<Map<String, dynamic>> following) async {
    final prefs = await _getPrefs();

    // Store full following data as JSON
    final followingJson = jsonEncode(following);
    await prefs.setString(_followingKey, followingJson);

    // Store following IDs separately for quick comparison
    final followingIds = following.map((f) => f['id'] as String).toList();
    await prefs.setStringList(_followingIdsKey, followingIds);

    // Update sync timestamp
    await _updateSyncTimestamp('following');
  }

  /// Retrieve cached following
  Future<List<Map<String, dynamic>>?> getCachedFollowing() async {
    final prefs = await _getPrefs();
    final followingJson = prefs.getString(_followingKey);

    if (followingJson == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(followingJson);
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        // Restore DateTime objects
        if (map['followDate'] is String) {
          map['followDate'] = DateTime.parse(map['followDate']);
        }
        if (map['lastInteraction'] is String) {
          map['lastInteraction'] = DateTime.parse(map['lastInteraction']);
        }
        return map;
      }).toList();
    } catch (e) {
      return null;
    }
  }

  /// Get cached following IDs only (lightweight)
  Future<List<String>> getCachedFollowingIds() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_followingIdsKey) ?? [];
  }

  // ==================== NOTIFICATIONS CACHING ====================

  /// Cache notifications with optimized storage
  Future<void> cacheNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    final prefs = await _getPrefs();

    // Keep only last 200 notifications
    final notificationsToStore = notifications.take(200).toList();

    // Store as JSON for better structure preservation
    final notificationsJson = jsonEncode(notificationsToStore);
    await prefs.setString(_notificationsKey, notificationsJson);

    // Update sync timestamp
    await _updateSyncTimestamp('notifications');
  }

  /// Retrieve cached notifications
  Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    final prefs = await _getPrefs();
    final notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(notificationsJson);
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        // Restore DateTime objects
        if (map['timestamp'] is String) {
          map['timestamp'] = DateTime.parse(map['timestamp']);
        }
        return map;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Update notification read status
  Future<void> updateNotificationReadStatus(
    int notificationId,
    bool isRead,
  ) async {
    final notifications = await getCachedNotifications();
    final index = notifications.indexWhere((n) => n['id'] == notificationId);

    if (index != -1) {
      notifications[index]['isRead'] = isRead;
      await cacheNotifications(notifications);
    }
  }

  /// Delete notification from cache
  Future<void> deleteNotificationFromCache(int notificationId) async {
    final notifications = await getCachedNotifications();
    notifications.removeWhere((n) => n['id'] == notificationId);
    await cacheNotifications(notifications);
  }

  // ==================== ANALYTICS CACHING ====================

  /// Cache analytics data
  Future<void> cacheAnalytics(Map<String, dynamic> analyticsData) async {
    final prefs = await _getPrefs();

    // Store analytics as JSON
    final analyticsJson = jsonEncode(analyticsData);
    await prefs.setString(_analyticsKey, analyticsJson);

    // Update sync timestamp
    await _updateSyncTimestamp('analytics');
  }

  /// Retrieve cached analytics
  Future<Map<String, dynamic>?> getCachedAnalytics() async {
    final prefs = await _getPrefs();
    final analyticsJson = prefs.getString(_analyticsKey);

    if (analyticsJson == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(analyticsJson));
    } catch (e) {
      return null;
    }
  }

  // ==================== DASHBOARD METRICS CACHING ====================

  /// Cache dashboard metrics
  Future<void> cacheDashboardMetrics(Map<String, dynamic> metrics) async {
    final prefs = await _getPrefs();

    // Store metrics as JSON
    final metricsJson = jsonEncode(metrics);
    await prefs.setString(_dashboardMetricsKey, metricsJson);

    // Update sync timestamp
    await _updateSyncTimestamp('dashboard');
  }

  /// Retrieve cached dashboard metrics
  Future<Map<String, dynamic>?> getCachedDashboardMetrics() async {
    final prefs = await _getPrefs();
    final metricsJson = prefs.getString(_dashboardMetricsKey);

    if (metricsJson == null) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(metricsJson));
    } catch (e) {
      return null;
    }
  }

  // ==================== USER PROFILE CACHING ====================

  /// Cache user profile
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    final prefs = await _getPrefs();

    // Store profile as JSON
    final profileJson = jsonEncode(profile);
    await prefs.setString(_userProfileKey, profileJson);

    // Update sync timestamp
    await _updateSyncTimestamp('profile');
  }

  /// Retrieve cached user profile
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    final prefs = await _getPrefs();
    final profileJson = prefs.getString(_userProfileKey);

    if (profileJson == null) return null;

    try {
      final profile = Map<String, dynamic>.from(jsonDecode(profileJson));
      // Restore DateTime objects
      if (profile['joinDate'] is String) {
        profile['joinDate'] = DateTime.parse(profile['joinDate']);
      }
      if (profile['lastActive'] is String) {
        profile['lastActive'] = DateTime.parse(profile['lastActive']);
      }
      return profile;
    } catch (e) {
      return null;
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Update sync timestamp for a specific data type
  Future<void> _updateSyncTimestamp(String dataType) async {
    final prefs = await _getPrefs();
    final timestamp = DateTime.now().toIso8601String();
    await prefs.setString('${_lastSyncKey}_$dataType', timestamp);
  }

  /// Get last sync time for a specific data type
  Future<DateTime?> getLastSyncTime(String dataType) async {
    final prefs = await _getPrefs();
    final timestamp = prefs.getString('${_lastSyncKey}_$dataType');

    if (timestamp == null) return null;

    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Check if cache is expired for a specific data type
  Future<bool> isCacheExpired(String dataType, int expiryHours) async {
    final lastSync = await getLastSyncTime(dataType);

    if (lastSync == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    return difference.inHours >= expiryHours;
  }

  /// Check if followers cache is expired
  Future<bool> isFollowersCacheExpired() async {
    return await isCacheExpired('followers', _followersCacheExpiry);
  }

  /// Check if analytics cache is expired
  Future<bool> isAnalyticsCacheExpired() async {
    return await isCacheExpired('analytics', _analyticsCacheExpiry);
  }

  /// Check if notifications cache is expired
  Future<bool> isNotificationsCacheExpired() async {
    return await isCacheExpired('notifications', _notificationsCacheExpiry);
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    final prefs = await _getPrefs();
    await prefs.remove(_followersKey);
    await prefs.remove(_followingKey);
    await prefs.remove(_notificationsKey);
    await prefs.remove(_analyticsKey);
    await prefs.remove(_dashboardMetricsKey);
    await prefs.remove(_userProfileKey);
    await prefs.remove(_followerIdsKey);
    await prefs.remove(_followingIdsKey);

    // Clear all sync timestamps
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_lastSyncKey)) {
        await prefs.remove(key);
      }
    }
  }

  /// Clear specific cache type
  Future<void> clearCache(String dataType) async {
    final prefs = await _getPrefs();

    switch (dataType) {
      case 'followers':
        await prefs.remove(_followersKey);
        await prefs.remove(_followerIdsKey);
        break;
      case 'following':
        await prefs.remove(_followingKey);
        await prefs.remove(_followingIdsKey);
        break;
      case 'notifications':
        await prefs.remove(_notificationsKey);
        break;
      case 'analytics':
        await prefs.remove(_analyticsKey);
        break;
      case 'dashboard':
        await prefs.remove(_dashboardMetricsKey);
        break;
      case 'profile':
        await prefs.remove(_userProfileKey);
        break;
    }

    await prefs.remove('${_lastSyncKey}_$dataType');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final prefs = await _getPrefs();

    return {
      'hasFollowers': prefs.containsKey(_followersKey),
      'hasFollowing': prefs.containsKey(_followingKey),
      'hasNotifications': prefs.containsKey(_notificationsKey),
      'hasAnalytics': prefs.containsKey(_analyticsKey),
      'hasDashboard': prefs.containsKey(_dashboardMetricsKey),
      'hasProfile': prefs.containsKey(_userProfileKey),
      'followersLastSync': await getLastSyncTime('followers'),
      'followingLastSync': await getLastSyncTime('following'),
      'notificationsLastSync': await getLastSyncTime('notifications'),
      'analyticsLastSync': await getLastSyncTime('analytics'),
      'dashboardLastSync': await getLastSyncTime('dashboard'),
      'profileLastSync': await getLastSyncTime('profile'),
    };
  }
}
