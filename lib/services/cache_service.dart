import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache Service - Stores data locally on the device for offline access
/// This is a singleton (only one instance exists throughout the app)
///
/// Main responsibilities:
/// - Save followers and following lists locally
/// - Store notifications for offline viewing
/// - Cache analytics data to reduce API calls
/// - Manage cache expiration times
/// - Provide quick access to stored data
class CacheService {
  // Singleton pattern - ensures only one instance exists
  static final CacheService _instance = CacheService._internal();
  SharedPreferences? _prefs; // Local storage instance

  // Keys used to store different types of data
  static const String _followersKey = 'cached_followers';
  static const String _followingKey = 'cached_following';
  static const String _notificationsKey = 'cached_notifications';
  static const String _analyticsKey = 'cached_analytics';
  static const String _dashboardMetricsKey = 'cached_dashboard_metrics';
  static const String _userProfileKey = 'cached_user_profile';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _followerIdsKey = 'cached_follower_ids';
  static const String _followingIdsKey = 'cached_following_ids';

  // How long before cached data expires (in hours)
  static const int _followersCacheExpiry = 24; // 24 hours
  static const int _analyticsCacheExpiry = 12; // 12 hours
  static const int _notificationsCacheExpiry = 48; // 48 hours

  // Factory constructor returns the same instance every time
  factory CacheService() {
    return _instance;
  }

  // Private constructor - called only once
  CacheService._internal();

  /// Initialize the local storage system
  /// Must be called before using any cache methods
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the SharedPreferences instance, initializing if needed
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  // ==================== FOLLOWERS CACHING ====================

  /// Save followers list to local storage
  /// Also saves just the IDs separately for quick comparisons
  ///
  /// Parameters:
  /// - followers: List of follower data to cache
  Future<void> cacheFollowers(List<Map<String, dynamic>> followers) async {
    final prefs = await _getPrefs();

    // Convert followers list to JSON string for storage
    final followersJson = jsonEncode(followers);
    await prefs.setString(_followersKey, followersJson);

    // Store just the IDs separately (faster to load and compare)
    final followerIds = followers.map((f) => f['id'] as String).toList();
    await prefs.setStringList(_followerIdsKey, followerIds);

    // Record when this data was saved
    await _updateSyncTimestamp('followers');
  }

  /// Get cached followers from local storage
  /// Returns null if no cached data exists
  Future<List<Map<String, dynamic>>?> getCachedFollowers() async {
    final prefs = await _getPrefs();
    final followersJson = prefs.getString(_followersKey);

    if (followersJson == null) return null;

    try {
      // Convert JSON string back to list of maps
      final List<dynamic> decoded = jsonDecode(followersJson);
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        // Convert date strings back to DateTime objects
        if (map['followDate'] is String) {
          map['followDate'] = DateTime.parse(map['followDate']);
        }
        return map;
      }).toList();
    } catch (e) {
      // Return null if data is corrupted
      return null;
    }
  }

  /// Get just the follower IDs (lightweight, faster than full data)
  /// Useful for quick comparisons without loading all follower details
  Future<List<String>> getCachedFollowerIds() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_followerIdsKey) ?? [];
  }

  // ==================== FOLLOWING CACHING ====================

  /// Save following list to local storage
  /// Also saves just the IDs separately for quick comparisons
  Future<void> cacheFollowing(List<Map<String, dynamic>> following) async {
    final prefs = await _getPrefs();

    // Convert following list to JSON string
    final followingJson = jsonEncode(following);
    await prefs.setString(_followingKey, followingJson);

    // Store just the IDs separately
    final followingIds = following.map((f) => f['id'] as String).toList();
    await prefs.setStringList(_followingIdsKey, followingIds);

    // Record when this data was saved
    await _updateSyncTimestamp('following');
  }

  /// Get cached following list from local storage
  /// Returns null if no cached data exists
  Future<List<Map<String, dynamic>>?> getCachedFollowing() async {
    final prefs = await _getPrefs();
    final followingJson = prefs.getString(_followingKey);

    if (followingJson == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(followingJson);
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        // Restore DateTime objects from strings
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

  /// Get just the following IDs (lightweight, faster than full data)
  Future<List<String>> getCachedFollowingIds() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_followingIdsKey) ?? [];
  }

  // ==================== NOTIFICATIONS CACHING ====================

  /// Save notifications to local storage
  /// Only keeps the most recent 200 notifications to save space
  Future<void> cacheNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    final prefs = await _getPrefs();

    // Limit to 200 most recent notifications to save storage space
    final notificationsToStore = notifications.take(200).toList();

    // Convert to JSON string
    final notificationsJson = jsonEncode(notificationsToStore);
    await prefs.setString(_notificationsKey, notificationsJson);

    // Record when this data was saved
    await _updateSyncTimestamp('notifications');
  }

  /// Get cached notifications from local storage
  /// Returns empty list if no cached data exists
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

  /// Mark a notification as read or unread
  /// Updates the cached notification without fetching from server
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

  /// Delete a notification from cache
  Future<void> deleteNotificationFromCache(int notificationId) async {
    final notifications = await getCachedNotifications();
    notifications.removeWhere((n) => n['id'] == notificationId);
    await cacheNotifications(notifications);
  }

  // ==================== ANALYTICS CACHING ====================

  /// Save analytics data to local storage
  Future<void> cacheAnalytics(Map<String, dynamic> analyticsData) async {
    final prefs = await _getPrefs();

    // Convert analytics to JSON string
    final analyticsJson = jsonEncode(analyticsData);
    await prefs.setString(_analyticsKey, analyticsJson);

    // Record when this data was saved
    await _updateSyncTimestamp('analytics');
  }

  /// Get cached analytics from local storage
  /// Returns null if no cached data exists
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

  /// Save dashboard metrics to local storage
  Future<void> cacheDashboardMetrics(Map<String, dynamic> metrics) async {
    final prefs = await _getPrefs();

    // Convert metrics to JSON string
    final metricsJson = jsonEncode(metrics);
    await prefs.setString(_dashboardMetricsKey, metricsJson);

    // Record when this data was saved
    await _updateSyncTimestamp('dashboard');
  }

  /// Get cached dashboard metrics from local storage
  /// Returns null if no cached data exists
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
