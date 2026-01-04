import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './cache_service.dart';

/// TikTok Service for fetching real follower and following data
/// Singleton service that handles TikTok API integration
class TikTokService {
  static final TikTokService _instance = TikTokService._internal();
  late final Dio _dio;
  final CacheService _cacheService = CacheService();
  static const String apiKey = String.fromEnvironment('TIKTOK_API_KEY');
  static const String apiBaseUrl = String.fromEnvironment(
    'TIKTOK_API_BASE_URL',
    defaultValue: 'https://open.tiktokapis.com/v2',
  );

  factory TikTokService() {
    return _instance;
  }

  TikTokService._internal() {
    _initializeService();
  }

  void _initializeService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Dio get dio => _dio;

  /// Get access token from storage
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tiktok_access_token');
  }

  /// Fetch followers list from TikTok API
  /// Returns list sorted by latest followers first
  Future<List<Map<String, dynamic>>> fetchFollowers() async {
    try {
      // Try to get from cache first if offline
      final cachedFollowers = await _cacheService.getCachedFollowers();
      final isCacheExpired = await _cacheService.isFollowersCacheExpired();

      final accessToken = await _getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        // Return cached data if available when not authenticated
        if (cachedFollowers != null) {
          return cachedFollowers;
        }
        throw TikTokException(
          statusCode: 401,
          message: 'No access token found. Please login with TikTok.',
        );
      }

      // For mock/testing mode, return sample data
      if (accessToken == 'mock_tiktok_access_token_for_testing') {
        final mockData = _generateMockFollowers();
        await _cacheService.cacheFollowers(mockData);
        return mockData;
      }

      // Return cached data if not expired
      if (cachedFollowers != null && !isCacheExpired) {
        return cachedFollowers;
      }

      final response = await _dio.get(
        '/user/followers/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        queryParameters: {
          'fields':
              'id,username,display_name,avatar_url,follower_count,bio,is_verified',
          'max_count': 100,
        },
      );

      final List<dynamic> data = response.data['data']['user_list'] ?? [];
      final followers = data.map((user) {
        return {
          'id': user['id'] ?? '',
          'username': user['username'] ?? '',
          'displayName': user['display_name'] ?? '',
          'profileImage': user['avatar_url'] ?? '',
          'semanticLabel':
              'Profile photo of ${user['display_name'] ?? user['username']}',
          'followDate':
              DateTime.now(), // TikTok API doesn't provide follow date in basic endpoint
          'isMutual':
              false, // Will be determined by cross-referencing with following list
          'isVerified': user['is_verified'] ?? false,
          'engagementLevel': _calculateEngagementLevel(user),
          'followerCount': user['follower_count'] ?? 0,
          'bio': user['bio'] ?? '',
        };
      }).toList();

      // Sort by latest first (most recent follows at top)
      followers.sort(
        (a, b) => (b['followDate'] as DateTime).compareTo(
          a['followDate'] as DateTime,
        ),
      );

      // Cache the fetched data
      await _cacheService.cacheFollowers(followers);

      return followers;
    } on DioException catch (e) {
      // Return cached data if API fails
      final cachedFollowers = await _cacheService.getCachedFollowers();
      if (cachedFollowers != null) {
        return cachedFollowers;
      }

      throw TikTokException(
        statusCode: e.response?.statusCode ?? 500,
        message:
            e.response?.data['error']?['message'] ??
            e.message ??
            'Failed to fetch followers',
      );
    }
  }

  /// Fetch following list from TikTok API
  /// Returns list sorted by latest follows first
  Future<List<Map<String, dynamic>>> fetchFollowing() async {
    try {
      // Try to get from cache first if offline
      final cachedFollowing = await _cacheService.getCachedFollowing();
      final isCacheExpired = await _cacheService.isFollowersCacheExpired();

      final accessToken = await _getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        // Return cached data if available when not authenticated
        if (cachedFollowing != null) {
          return cachedFollowing;
        }
        throw TikTokException(
          statusCode: 401,
          message: 'No access token found. Please login with TikTok.',
        );
      }

      // For mock/testing mode, return sample data
      if (accessToken == 'mock_tiktok_access_token_for_testing') {
        final mockData = _generateMockFollowing();
        await _cacheService.cacheFollowing(mockData);
        return mockData;
      }

      // Return cached data if not expired
      if (cachedFollowing != null && !isCacheExpired) {
        return cachedFollowing;
      }

      final response = await _dio.get(
        '/user/following/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        queryParameters: {
          'fields':
              'id,username,display_name,avatar_url,follower_count,bio,is_verified',
          'max_count': 100,
        },
      );

      final List<dynamic> data = response.data['data']['user_list'] ?? [];
      final following = data.map((user) {
        return {
          'id': user['id'] ?? '',
          'username': user['username'] ?? '',
          'displayName': user['display_name'] ?? '',
          'avatar': user['avatar_url'] ?? '',
          'semanticLabel':
              'Profile photo of ${user['display_name'] ?? user['username']}',
          'followDate':
              DateTime.now(), // TikTok API doesn't provide follow date in basic endpoint
          'followsBack':
              false, // Will be determined by cross-referencing with followers list
          'lastInteraction': DateTime.now().subtract(
            Duration(days: (user['follower_count'] ?? 0) % 30),
          ),
          'engagementScore': _calculateEngagementScore(user),
          'contentCategory': _inferContentCategory(user['bio'] ?? ''),
          'mutualConnections': 0, // Would require additional API calls
          'isActive': true,
        };
      }).toList();

      // Sort by latest first (most recent follows at top)
      following.sort(
        (a, b) => (b['followDate'] as DateTime).compareTo(
          a['followDate'] as DateTime,
        ),
      );

      // Cache the fetched data
      await _cacheService.cacheFollowing(following);

      return following;
    } on DioException catch (e) {
      // Return cached data if API fails
      final cachedFollowing = await _cacheService.getCachedFollowing();
      if (cachedFollowing != null) {
        return cachedFollowing;
      }

      throw TikTokException(
        statusCode: e.response?.statusCode ?? 500,
        message:
            e.response?.data['error']?['message'] ??
            e.message ??
            'Failed to fetch following',
      );
    }
  }

  /// Cross-reference followers and following to determine mutual relationships
  Future<Map<String, dynamic>> fetchFollowerRelationships() async {
    final followers = await fetchFollowers();
    final following = await fetchFollowing();

    // Create sets for quick lookup
    final followerIds = followers.map((f) => f['id']).toSet();
    final followingIds = following.map((f) => f['id']).toSet();

    // Update mutual status
    for (var follower in followers) {
      follower['isMutual'] = followingIds.contains(follower['id']);
    }

    for (var follow in following) {
      follow['followsBack'] = followerIds.contains(follow['id']);
    }

    return {
      'followers': followers,
      'following': following,
      'totalFollowers': followers.length,
      'totalFollowing': following.length,
      'mutualCount': followers.where((f) => f['isMutual'] == true).length,
      'notFollowingBackCount': following
          .where((f) => f['followsBack'] == false)
          .length,
    };
  }

  /// Calculate engagement level based on follower count and activity
  String _calculateEngagementLevel(Map<String, dynamic> user) {
    final followerCount = user['follower_count'] ?? 0;
    if (followerCount > 100000) return 'high';
    if (followerCount > 10000) return 'medium';
    return 'low';
  }

  /// Calculate engagement score (0-100)
  int _calculateEngagementScore(Map<String, dynamic> user) {
    final followerCount = user['follower_count'] ?? 0;
    final isVerified = user['is_verified'] ?? false;

    int score = 50; // Base score

    // Adjust based on follower count
    if (followerCount > 100000) {
      score += 30;
    } else if (followerCount > 10000) {
      score += 20;
    } else if (followerCount > 1000) {
      score += 10;
    }

    // Bonus for verified accounts
    if (isVerified) score += 20;

    return score.clamp(0, 100);
  }

  /// Infer content category from bio
  String _inferContentCategory(String bio) {
    final bioLower = bio.toLowerCase();

    if (bioLower.contains('fitness') ||
        bioLower.contains('workout') ||
        bioLower.contains('gym')) {
      return 'Fitness';
    } else if (bioLower.contains('food') ||
        bioLower.contains('recipe') ||
        bioLower.contains('cooking')) {
      return 'Food';
    } else if (bioLower.contains('travel') || bioLower.contains('adventure')) {
      return 'Travel';
    } else if (bioLower.contains('tech') ||
        bioLower.contains('gadget') ||
        bioLower.contains('developer')) {
      return 'Technology';
    } else if (bioLower.contains('fashion') || bioLower.contains('style')) {
      return 'Fashion';
    } else if (bioLower.contains('music') ||
        bioLower.contains('artist') ||
        bioLower.contains('producer')) {
      return 'Music';
    } else if (bioLower.contains('art') ||
        bioLower.contains('design') ||
        bioLower.contains('creative')) {
      return 'Art';
    } else if (bioLower.contains('business') ||
        bioLower.contains('entrepreneur')) {
      return 'Business';
    } else if (bioLower.contains('comedy') || bioLower.contains('funny')) {
      return 'Comedy';
    } else if (bioLower.contains('beauty') || bioLower.contains('makeup')) {
      return 'Beauty';
    }

    return 'Lifestyle';
  }

  /// Generate mock followers for testing
  List<Map<String, dynamic>> _generateMockFollowers() {
    return List.generate(25, (index) {
      final usernames = [
        'sarah_creates',
        'mike_fitness',
        'emma_travel',
        'alex_tech',
        'lisa_food',
        'john_music',
        'kate_fashion',
        'david_art',
        'sophia_beauty',
        'ryan_comedy',
        'olivia_dance',
        'noah_gaming',
        'ava_lifestyle',
        'liam_sports',
        'mia_pets',
        'ethan_cars',
        'isabella_books',
        'mason_diy',
        'charlotte_yoga',
        'logan_crypto',
        'amelia_plants',
        'lucas_photography',
        'harper_cooking',
        'jackson_fitness',
        'evelyn_motivation',
      ];

      return {
        'id': 'follower_$index',
        'username': usernames[index],
        'displayName': usernames[index]
            .split('_')
            .map((s) => s[0].toUpperCase() + s.substring(1))
            .join(' '),
        'profileImage': 'https://i.pravatar.cc/150?img=${index + 1}',
        'semanticLabel': 'Profile photo of ${usernames[index]}',
        'followDate': DateTime.now().subtract(Duration(days: index)),
        'isMutual': index % 3 == 0,
        'isVerified': index % 5 == 0,
        'engagementLevel': index % 3 == 0
            ? 'high'
            : (index % 2 == 0 ? 'medium' : 'low'),
        'followerCount': 1000 + (index * 500),
        'bio': 'Content creator | ${usernames[index].split('_')[1]} enthusiast',
      };
    });
  }

  /// Generate mock following for testing
  List<Map<String, dynamic>> _generateMockFollowing() {
    return List.generate(30, (index) {
      final usernames = [
        'creator_one',
        'influencer_two',
        'artist_three',
        'chef_four',
        'trainer_five',
        'blogger_six',
        'vlogger_seven',
        'streamer_eight',
        'musician_nine',
        'dancer_ten',
        'comedian_eleven',
        'gamer_twelve',
        'photographer_thirteen',
        'writer_fourteen',
        'designer_fifteen',
        'developer_sixteen',
        'entrepreneur_seventeen',
        'coach_eighteen',
        'teacher_nineteen',
        'mentor_twenty',
        'advisor_twentyone',
        'consultant_twentytwo',
        'expert_twentythree',
        'specialist_twentyfour',
        'professional_twentyfive',
        'guru_twentysix',
        'master_twentyseven',
        'legend_twentyeight',
        'icon_twentynine',
        'star_thirty',
      ];

      return {
        'id': 'following_$index',
        'username': usernames[index],
        'displayName': usernames[index]
            .split('_')
            .map((s) => s[0].toUpperCase() + s.substring(1))
            .join(' '),
        'avatar': 'https://i.pravatar.cc/150?img=${index + 30}',
        'semanticLabel': 'Profile photo of ${usernames[index]}',
        'followDate': DateTime.now().subtract(Duration(days: index * 2)),
        'followsBack': index % 4 != 0,
        'lastInteraction': DateTime.now().subtract(Duration(days: index)),
        'engagementScore': 50 + (index % 50),
        'contentCategory': [
          'Fitness',
          'Food',
          'Travel',
          'Tech',
          'Fashion',
        ][index % 5],
        'mutualConnections': index % 3,
        'isActive': index % 5 != 0,
      };
    });
  }

  /// Generate mock user profile for testing
  Future<Map<String, dynamic>> _generateMockUserProfile() async {
    final relationships = await fetchFollowerRelationships();

    return {
      'id': 'current_user_123',
      'username': 'my_tiktok_account',
      'displayName': 'My TikTok Account',
      'profileImage': 'https://i.pravatar.cc/150?img=50',
      'semanticLabel': 'Your profile picture',
      'isVerified': false,
      'followersCount': relationships['totalFollowers'],
      'followingCount': relationships['totalFollowing'],
      'likesCount': 15420,
      'videoCount': 48,
      'bio': 'TikTok content creator | Tracking my growth 📈',
      'joinDate': DateTime.now().subtract(const Duration(days: 365)),
      'lastActive': DateTime.now(),
      'avgLikes': 321,
      'avgComments': 16,
      'avgShares': 6,
      'isOwnProfile': true,
      'activityHistory': _generateActivityHistory(relationships),
      'mutualConnections': _extractMutualConnections(relationships),
      'recentPosts': [],
    };
  }

  /// Fetch current user's profile information
  /// Returns the signed-in user's own profile data
  Future<Map<String, dynamic>> fetchCurrentUserProfile() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw TikTokException(
          statusCode: 401,
          message: 'No access token found. Please login with TikTok.',
        );
      }

      // For mock/testing mode, return sample data
      if (accessToken == 'mock_tiktok_access_token_for_testing') {
        return _generateMockUserProfile();
      }

      final response = await _dio.get(
        '/user/info/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        queryParameters: {
          'fields':
              'id,username,display_name,avatar_url,avatar_url_100,avatar_url_200,bio,follower_count,following_count,likes_count,video_count,is_verified',
        },
      );

      final user = response.data['data']['user'];

      // Fetch relationships data for activity and mutual connections
      final relationships = await fetchFollowerRelationships();

      // Calculate engagement metrics
      final videoCount = user['video_count'] ?? 1;
      final likesCount = user['likes_count'] ?? 0;
      final avgLikes = (likesCount / videoCount).round();

      return {
        'id': user['id'] ?? '',
        'username': user['username'] ?? '',
        'displayName': user['display_name'] ?? '',
        'profileImage':
            user['avatar_url_200'] ??
            user['avatar_url_100'] ??
            user['avatar_url'] ??
            '',
        'semanticLabel': 'Your profile picture',
        'isVerified': user['is_verified'] ?? false,
        'followersCount': user['follower_count'] ?? 0,
        'followingCount': user['following_count'] ?? 0,
        'likesCount': user['likes_count'] ?? 0,
        'videoCount': user['video_count'] ?? 0,
        'bio': user['bio'] ?? 'No bio available',
        'joinDate': DateTime.now().subtract(
          const Duration(days: 365),
        ), // TikTok API doesn't provide join date
        'lastActive': DateTime.now(),
        'avgLikes': avgLikes,
        'avgComments': (avgLikes * 0.05).round(), // Estimate 5% of likes
        'avgShares': (avgLikes * 0.02).round(), // Estimate 2% of likes
        'isOwnProfile': true, // Flag to indicate this is the user's own profile
        'activityHistory': _generateActivityHistory(relationships),
        'mutualConnections': _extractMutualConnections(relationships),
        'recentPosts':
            [], // Would require additional API endpoint for user's videos
      };
    } on DioException catch (e) {
      throw TikTokException(
        statusCode: e.response?.statusCode ?? 500,
        message:
            e.response?.data['error']?['message'] ??
            e.message ??
            'Failed to fetch user profile',
      );
    }
  }

  /// Generate activity history from relationships data
  List<Map<String, dynamic>> _generateActivityHistory(
    Map<String, dynamic> relationships,
  ) {
    final List<Map<String, dynamic>> activities = [];

    final followers = relationships['followers'] as List<Map<String, dynamic>>;
    final following = relationships['following'] as List<Map<String, dynamic>>;

    // Add recent follower activities (last 10)
    for (var i = 0; i < followers.length && i < 10; i++) {
      activities.add({
        'type': 'new_follower',
        'user': followers[i],
        'timestamp': followers[i]['followDate'],
      });
    }

    // Add recent following activities (last 10)
    for (var i = 0; i < following.length && i < 10; i++) {
      activities.add({
        'type': 'started_following',
        'user': following[i],
        'timestamp': following[i]['followDate'],
      });
    }

    // Sort by timestamp (latest first)
    activities.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );

    return activities.take(20).toList(); // Return top 20 activities
  }

  /// Extract mutual connections from relationships data
  List<Map<String, dynamic>> _extractMutualConnections(
    Map<String, dynamic> relationships,
  ) {
    final followers = relationships['followers'] as List<Map<String, dynamic>>;
    return followers.where((f) => f['isMutual'] == true).toList();
  }

  /// Fetch real-time notifications based on follower activity
  /// Compares current followers/following with stored data to detect changes
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      final List<Map<String, dynamic>> notifications = [];

      // Fetch current relationships
      final relationships = await fetchFollowerRelationships();
      final currentFollowers =
          relationships['followers'] as List<Map<String, dynamic>>;
      final currentFollowing =
          relationships['following'] as List<Map<String, dynamic>>;

      // Get stored previous state from cache service
      final previousFollowerIds = await _cacheService.getCachedFollowerIds();
      final previousFollowingIds = await _cacheService.getCachedFollowingIds();

      // Detect new followers
      final currentFollowerIds = currentFollowers
          .map((f) => f['id'] as String)
          .toList();

      for (final followerId in currentFollowerIds) {
        if (!previousFollowerIds.contains(followerId)) {
          final follower = currentFollowers.firstWhere(
            (f) => f['id'] == followerId,
          );

          notifications.add({
            'id': DateTime.now().millisecondsSinceEpoch + notifications.length,
            'type': follower['isMutual'] == true
                ? 'mutual_connection'
                : 'new_follower',
            'title': follower['isMutual'] == true
                ? 'New Mutual Connection!'
                : 'New Follower',
            'message': follower['isMutual'] == true
                ? '${follower['displayName']} followed you back!'
                : '${follower['displayName']} started following you',
            'avatar': follower['profileImage'],
            'semanticLabel': follower['semanticLabel'],
            'timestamp': DateTime.now(),
            'isRead': false,
            'actionable': true,
            'userId': follower['id'],
          });
        }
      }

      // Detect unfollows
      for (final followerId in previousFollowerIds) {
        if (!currentFollowerIds.contains(followerId)) {
          notifications.add({
            'id': DateTime.now().millisecondsSinceEpoch + notifications.length,
            'type': 'unfollow',
            'title': 'Someone Unfollowed',
            'message': 'A user has unfollowed you',
            'avatar': null,
            'semanticLabel': null,
            'timestamp': DateTime.now(),
            'isRead': false,
            'actionable': false,
            'userId': followerId,
          });
        }
      }

      // Detect milestone achievements
      if (currentFollowers.length >= 100 && previousFollowerIds.length < 100) {
        notifications.add({
          'id': DateTime.now().millisecondsSinceEpoch + notifications.length,
          'type': 'milestone',
          'title': '🎉 Milestone Achieved!',
          'message': 'You reached 100 followers!',
          'avatar': null,
          'semanticLabel': null,
          'timestamp': DateTime.now(),
          'isRead': false,
          'actionable': false,
          'userId': null,
        });
      }

      if (currentFollowers.length >= 500 && previousFollowerIds.length < 500) {
        notifications.add({
          'id': DateTime.now().millisecondsSinceEpoch + notifications.length,
          'type': 'milestone',
          'title': '🎉 Milestone Achieved!',
          'message': 'You reached 500 followers!',
          'avatar': null,
          'semanticLabel': null,
          'timestamp': DateTime.now(),
          'isRead': false,
          'actionable': false,
          'userId': null,
        });
      }

      // Store current state for next comparison using cache service
      await _cacheService.cacheFollowers(currentFollowers);
      await _cacheService.cacheFollowing(currentFollowing);

      // Get stored notifications and merge with new ones
      final storedNotifications = await _cacheService.getCachedNotifications();
      final allNotifications = [...notifications, ...storedNotifications];

      // Sort by timestamp (latest first)
      allNotifications.sort(
        (a, b) =>
            (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
      );

      // Store updated notifications using cache service
      await _cacheService.cacheNotifications(allNotifications);

      return allNotifications;
    } catch (e) {
      // Return stored notifications if API fails
      return await _cacheService.getCachedNotifications();
    }
  }

  /// Get stored notifications from local storage
  Future<List<Map<String, dynamic>>> _getStoredNotifications() async {
    return await _cacheService.getCachedNotifications();
  }

  /// Store notifications to local storage
  Future<void> _storeNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    await _cacheService.cacheNotifications(notifications);
  }

  /// Format number with K, M suffixes
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    await _cacheService.updateNotificationReadStatus(notificationId, true);
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    await _cacheService.deleteNotificationFromCache(notificationId);
  }

  /// Store access token after login
  Future<void> storeAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tiktok_access_token', token);
  }

  /// Clear access token on logout
  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tiktok_access_token');
  }
}

/// TikTok API Exception
class TikTokException implements Exception {
  final int statusCode;
  final String message;

  TikTokException({required this.statusCode, required this.message});

  @override
  String toString() => 'TikTokException($statusCode): $message';
}
