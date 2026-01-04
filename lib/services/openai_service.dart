import 'package:dio/dio.dart';

/// OpenAI Service - Uses AI to analyze your TikTok follower patterns
/// This is a singleton (only one instance exists throughout the app)
///
/// Main responsibilities:
/// - Generate smart suggestions for accounts to follow
/// - Analyze follower patterns and trends
/// - Provide AI-powered insights and recommendations
/// - Generate analytics for different time periods
class OpenAIService {
  // Singleton pattern - ensures only one instance exists
  static final OpenAIService _instance = OpenAIService._internal();
  late final Dio _dio; // HTTP client for making API requests to OpenAI

  // API key from environment variables (set during build)
  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');

  // Factory constructor returns the same instance every time
  factory OpenAIService() {
    return _instance;
  }

  // Private constructor - called only once
  OpenAIService._internal() {
    _initializeService();
  }

  /// Initialize the HTTP client with OpenAI API settings
  void _initializeService() {
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY must be provided via --dart-define');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey', // Authentication header
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  // Expose the HTTP client for advanced usage
  Dio get dio => _dio;

  /// Generate analytics insights for a specific time period
  /// This is a convenience method that uses OpenAIClient internally
  ///
  /// Parameters:
  /// - followers: Your current followers list
  /// - following: Accounts you're following
  /// - period: Time period ('week', 'month', or 'year')
  ///
  /// Returns a map with growth rates, trends, insights, and recommendations
  Future<Map<String, dynamic>> generateAnalyticsInsights({
    required List<Map<String, dynamic>> followers,
    required List<Map<String, dynamic>> following,
    required String period,
  }) async {
    final client = OpenAIClient(_dio);
    return client.generateAnalyticsInsights(
      followers: followers,
      following: following,
      period: period,
    );
  }
}

/// OpenAI Client - Handles the actual AI analysis logic
/// Separated from OpenAIService for better code organization
class OpenAIClient {
  final Dio dio; // HTTP client passed from OpenAIService

  OpenAIClient(this.dio);

  /// Generate smart suggestions for accounts to follow
  /// Uses AI to analyze your network and recommend relevant accounts
  ///
  /// Parameters:
  /// - followers: Your current followers
  /// - following: Accounts you're following
  ///
  /// Returns a list of suggested accounts with reasons why you should follow them
  Future<List<Map<String, dynamic>>> generateSmartSuggestions({
    required List<Map<String, dynamic>> followers,
    required List<Map<String, dynamic>> following,
  }) async {
    try {
      // Build a detailed prompt for the AI
      final suggestionsPrompt = _buildSuggestionsPrompt(followers, following);

      // Request data for OpenAI API
      final requestData = {
        'model': 'gpt-4o-mini', // AI model to use
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an expert social media growth strategist. Analyze follower patterns and generate 5-8 smart account suggestions that would benefit the user based on their current network, engagement patterns, and content interests. Return ONLY valid JSON array with format: [{"username": "@user", "displayName": "Name", "reason": "why follow", "category": "content type", "potentialValue": "high/medium/low"}]',
          },
          {'role': 'user', 'content': suggestionsPrompt},
        ],
        'max_tokens': 1000, // Maximum length of AI response
        'temperature': 0.7, // Creativity level (0.0 = focused, 1.0 = creative)
      };

      // Send request to OpenAI
      final response = await dio.post('/chat/completions', data: requestData);
      final content = response.data['choices'][0]['message']['content'];

      // Parse the AI's response into a usable format
      return _parseSuggestions(content);
    } on DioException catch (e) {
      // Handle network errors
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message:
            e.response?.data['error']?['message'] ??
            e.message ??
            'Failed to generate suggestions',
      );
    }
  }

  /// Build a detailed prompt for the AI to analyze
  /// Includes information about your current network and interests
  String _buildSuggestionsPrompt(
    List<Map<String, dynamic>> followers,
    List<Map<String, dynamic>> following,
  ) {
    // Analyze what types of content you're interested in
    final categories = <String, int>{};
    final highEngagement = <String>[];

    for (var follow in following) {
      final category = follow['contentCategory'] ?? 'Lifestyle';
      categories[category] = (categories[category] ?? 0) + 1;

      // Track accounts you engage with frequently
      if ((follow['engagementScore'] ?? 0) > 70) {
        highEngagement.add(follow['username'] ?? '');
      }
    }

    // Sort categories by popularity
    final topCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Create a detailed prompt for the AI
    return '''
Analyze this TikTok user's network and generate smart follow suggestions:

CURRENT NETWORK:
- Following: ${following.length} accounts
- Followers: ${followers.length} accounts
- Top content interests: ${topCategories.take(3).map((e) => '${e.key} (${e.value})').join(', ')}
- High engagement accounts: ${highEngagement.take(5).join(', ')}

MUTUAL CONNECTIONS:
${followers.where((f) => f['isMutual'] == true).take(5).map((f) => '- ${f['username']}: ${f['bio'] ?? 'No bio'}').join('\n')}

GENERATE 5-8 SUGGESTIONS:
Based on their interests and network, suggest accounts they should follow. Consider:
1. Similar content categories to what they already engage with
2. Accounts that could expand their network strategically
3. Verified creators in their interest areas
4. Accounts with high engagement potential

Return ONLY this JSON structure:
[
  {
    "username": "@suggested_user",
    "displayName": "Display Name",
    "reason": "Brief explanation why this account is valuable",
    "category": "Content Category",
    "potentialValue": "high"
  }
]
''';
  }

  /// Parse the AI's response text into a structured list
  /// Handles different response formats (plain JSON or markdown code blocks)
  List<Map<String, dynamic>> _parseSuggestions(String content) {
    try {
      // Remove markdown code block formatting if present
      String jsonContent = content.trim();
      if (jsonContent.contains('```json')) {
        final startIndex = jsonContent.indexOf('```json') + 7;
        final endIndex = jsonContent.lastIndexOf('```');
        jsonContent = jsonContent.substring(startIndex, endIndex).trim();
      } else if (jsonContent.contains('```')) {
        final startIndex = jsonContent.indexOf('```') + 3;
        final endIndex = jsonContent.lastIndexOf('```');
        jsonContent = jsonContent.substring(startIndex, endIndex).trim();
      }

      // Extract suggestion objects using regex pattern matching
      final suggestions = <Map<String, dynamic>>[];
      final regex = RegExp(
        r'\{[^}]*"username"\s*:\s*"([^"]+)"[^}]*"displayName"\s*:\s*"([^"]+)"[^}]*"reason"\s*:\s*"([^"]+)"[^}]*"category"\s*:\s*"([^"]+)"[^}]*"potentialValue"\s*:\s*"([^"]+)"[^}]*\}',
        dotAll: true,
      );

      final matches = regex.allMatches(jsonContent);
      for (var match in matches) {
        suggestions.add({
          'username': match.group(1) ?? '',
          'displayName': match.group(2) ?? '',
          'reason': match.group(3) ?? '',
          'category': match.group(4) ?? '',
          'potentialValue': match.group(5) ?? 'medium',
        });
      }

      // Return suggestions or fallback if parsing failed
      return suggestions.isNotEmpty ? suggestions : _getFallbackSuggestions();
    } catch (e) {
      // If anything goes wrong, return fallback suggestions
      return _getFallbackSuggestions();
    }
  }

  /// Provide fallback suggestions if AI analysis fails
  List<Map<String, dynamic>> _getFallbackSuggestions() {
    return [
      {
        'username': '@trending_creator',
        'displayName': 'Trending Creator',
        'reason': 'Popular content in your interest area',
        'category': 'Lifestyle',
        'potentialValue': 'high',
      },
    ];
  }

  /// Generate analytics insights for different time periods
  /// Uses AI to analyze growth trends and provide recommendations
  ///
  /// Parameters:
  /// - followers: Your current followers
  /// - following: Accounts you're following
  /// - period: Time period to analyze ('week', 'month', or 'year')
  ///
  /// Returns insights including growth rate, trends, and recommendations
  Future<Map<String, dynamic>> generateAnalyticsInsights({
    required List<Map<String, dynamic>> followers,
    required List<Map<String, dynamic>> following,
    required String period,
  }) async {
    try {
      // Build a detailed prompt for analytics
      final insightsPrompt = _buildAnalyticsPrompt(
        followers,
        following,
        period,
      );

      final requestData = {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a social media analytics expert. Analyze follower/following data for the specified time period and provide insights on growth trends, engagement patterns, and actionable recommendations. Return ONLY valid JSON with format: {"growthRate": number, "engagementTrend": "up/down/stable", "topInsights": ["insight1", "insight2"], "recommendations": ["rec1", "rec2"], "keyMetrics": {"newFollowers": number, "unfollows": number, "mutualConnections": number}}',
          },
          {'role': 'user', 'content': insightsPrompt},
        ],
        'max_tokens': 800,
        'temperature': 0.6, // Slightly more focused for analytics
      };

      final response = await dio.post('/chat/completions', data: requestData);
      final content = response.data['choices'][0]['message']['content'];

      // Parse and return the analytics insights
      return _parseAnalyticsInsights(content, period);
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message:
            e.response?.data['error']?['message'] ??
            e.message ??
            'Failed to generate analytics insights',
      );
    }
  }

  /// Build a detailed prompt for analytics insights
  String _buildAnalyticsPrompt(
    List<Map<String, dynamic>> followers,
    List<Map<String, dynamic>> following,
    String period,
  ) {
    // Calculate key metrics
    final mutualCount = followers.where((f) => f['isMutual'] == true).length;
    final notFollowingBack = following
        .where((f) => f['followsBack'] == false)
        .length;
    final highEngagement = following
        .where((f) => (f['engagementScore'] ?? 0) > 70)
        .length;

    return '''
Analyze this TikTok account's performance for the past $period:

CURRENT METRICS:
- Total Followers: ${followers.length}
- Total Following: ${following.length}
- Mutual Connections: $mutualCount
- Not Following Back: $notFollowingBack
- High Engagement Accounts: $highEngagement

TIME PERIOD: $period

Provide analytics insights including:
1. Estimated growth rate for this period
2. Engagement trend analysis
3. Top 3 insights about follower behavior
4. 2-3 actionable recommendations
5. Key metrics breakdown

Return ONLY this JSON structure:
{
  "growthRate": 5.2,
  "engagementTrend": "up",
  "topInsights": [
    "Insight about follower patterns",
    "Insight about engagement",
    "Insight about growth opportunities"
  ],
  "recommendations": [
    "Actionable recommendation 1",
    "Actionable recommendation 2"
  ],
  "keyMetrics": {
    "newFollowers": 15,
    "unfollows": 3,
    "mutualConnections": $mutualCount
  }
}
''';
  }

  /// Parse the AI's response into structured analytics data
  Map<String, dynamic> _parseAnalyticsInsights(String content, String period) {
    try {
      // Remove markdown code block formatting if present
      String jsonContent = content.trim();
      if (jsonContent.contains('```json')) {
        final startIndex = jsonContent.indexOf('```json') + 7;
        final endIndex = jsonContent.lastIndexOf('```');
        jsonContent = jsonContent.substring(startIndex, endIndex).trim();
      } else if (jsonContent.contains('```')) {
        final startIndex = jsonContent.indexOf('```') + 3;
        final endIndex = jsonContent.lastIndexOf('```');
        jsonContent = jsonContent.substring(startIndex, endIndex).trim();
      }

      // Extract key values using regex
      final growthRateMatch = RegExp(
        r'"growthRate"\s*:\s*([\d.]+)',
      ).firstMatch(jsonContent);
      final engagementMatch = RegExp(
        r'"engagementTrend"\s*:\s*"(\w+)"',
      ).firstMatch(jsonContent);

      final insightsMatches = RegExp(
        r'"topInsights"\s*:\s*\[([^\]]+)\]',
      ).firstMatch(jsonContent);
      final recommendationsMatches = RegExp(
        r'"recommendations"\s*:\s*\[([^\]]+)\]',
      ).firstMatch(jsonContent);

      final insights = <String>[];
      if (insightsMatches != null) {
        final insightsStr = insightsMatches.group(1) ?? '';
        final matches = RegExp(r'"([^"]+)"').allMatches(insightsStr);
        insights.addAll(matches.map((m) => m.group(1) ?? ''));
      }

      final recommendations = <String>[];
      if (recommendationsMatches != null) {
        final recsStr = recommendationsMatches.group(1) ?? '';
        final matches = RegExp(r'"([^"]+)"').allMatches(recsStr);
        recommendations.addAll(matches.map((m) => m.group(1) ?? ''));
      }

      return {
        'growthRate': double.tryParse(growthRateMatch?.group(1) ?? '0') ?? 0.0,
        'engagementTrend': engagementMatch?.group(1) ?? 'stable',
        'topInsights': insights.isNotEmpty
            ? insights
            : ['No insights available'],
        'recommendations': recommendations.isNotEmpty
            ? recommendations
            : ['Continue monitoring your account'],
        'keyMetrics': {
          'newFollowers': 0,
          'unfollows': 0,
          'mutualConnections': 0,
        },
      };
    } catch (e) {
      return _getFallbackAnalytics(period);
    }
  }

  /// Provide fallback analytics data if AI analysis fails
  Map<String, dynamic> _getFallbackAnalytics(String period) {
    return {
      'growthRate': 0.0,
      'engagementTrend': 'stable',
      'topInsights': ['Analytics data unavailable for $period'],
      'recommendations': ['Continue building your presence'],
      'keyMetrics': {'newFollowers': 0, 'unfollows': 0, 'mutualConnections': 0},
    };
  }

  /// Analyze follower patterns and detect unfollows
  /// Returns AI-generated insights about follower relationships
  Future<FollowerAnalysisResult> analyzeFollowerPatterns({
    required List<Map<String, dynamic>> followers,
    required List<Map<String, dynamic>> following,
  }) async {
    try {
      // Prepare analysis data
      final analysisPrompt = _buildAnalysisPrompt(followers, following);

      final requestData = {
        'model': 'gpt-5-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an expert social media analyst specializing in follower relationship patterns. Analyze the provided data and identify users who unfollowed despite being followed back, detect patterns, and provide actionable insights. Return your analysis in JSON format with keys: unfollowedUsers (array of {username, displayName, reason}), patterns (array of {pattern, description, severity}), recommendations (array of {category, suggestion, impact}).',
          },
          {'role': 'user', 'content': analysisPrompt},
        ],
        'max_completion_tokens': 1500,
        'reasoning_effort': 'medium',
      };

      final response = await dio.post('/chat/completions', data: requestData);

      final content = response.data['choices'][0]['message']['content'];
      return _parseAnalysisResult(content);
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message:
            e.response?.data['error']?['message'] ??
            e.message ??
            'Unknown error',
      );
    }
  }

  /// Build a detailed prompt for follower pattern analysis
  String _buildAnalysisPrompt(
    List<Map<String, dynamic>> followers,
    List<Map<String, dynamic>> following,
  ) {
    // Build follower summary
    final followerSummary = followers.map((f) {
      return {
        'username': f['username'],
        'displayName': f['displayName'],
        'isMutual': f['isMutual'],
        'engagementLevel': f['engagementLevel'],
        'followDate': f['followDate'].toString(),
      };
    }).toList();

    // Build following summary
    final followingSummary = following.map((f) {
      return {
        'username': f['username'],
        'displayName': f['displayName'],
        'followsBack': f['followsBack'],
        'engagementScore': f['engagementScore'],
        'lastInteraction': f['lastInteraction'].toString(),
        'isActive': f['isActive'],
      };
    }).toList();

    return '''
Analyze the following TikTok follower data:

FOLLOWERS (${followers.length} total):
${followerSummary.take(20).map((f) => '- ${f['username']}: mutual=${f['isMutual']}, engagement=${f['engagementLevel']}, since=${f['followDate']}').join('\n')}

FOLLOWING (${following.length} total):
${followingSummary.take(20).map((f) => '- ${f['username']}: followsBack=${f['followsBack']}, score=${f['engagementScore']}, active=${f['isActive']}').join('\n')}

TASK:
1. Identify users in FOLLOWING list where followsBack=false (they don't follow back despite being followed)
2. Cross-reference with FOLLOWERS list to detect who unfollowed after mutual connection
3. Detect patterns: engagement-based unfollows, inactive accounts, mass unfollow events
4. Provide actionable recommendations

Return ONLY valid JSON with this structure:
{
  "unfollowedUsers": [{"username": "@user", "displayName": "Name", "reason": "explanation"}],
  "patterns": [{"pattern": "Pattern Name", "description": "details", "severity": "high/medium/low"}],
  "recommendations": [{"category": "Category", "suggestion": "action", "impact": "high/medium/low"}]
}
''';
  }

  /// Parse the AI's analysis response into structured results
  FollowerAnalysisResult _parseAnalysisResult(String content) {
    try {
      // Remove markdown code block formatting if present
      String jsonContent = content.trim();
      if (jsonContent.contains('```json')) {
        final startIndex = jsonContent.indexOf('```json') + 7;
        final endIndex = jsonContent.lastIndexOf('```');
        jsonContent = jsonContent.substring(startIndex, endIndex).trim();
      } else if (jsonContent.contains('```')) {
        final startIndex = jsonContent.indexOf('```') + 3;
        final endIndex = jsonContent.lastIndexOf('```');
        jsonContent = jsonContent.substring(startIndex, endIndex).trim();
      }

      // Parse JSON
      final Map<String, dynamic> data = {};
      // Simple JSON parsing for the expected structure
      if (jsonContent.contains('unfollowedUsers')) {
        data['unfollowedUsers'] = [];
        data['patterns'] = [];
        data['recommendations'] = [];

        // Extract sections (simplified parsing)
        final lines = jsonContent.split('\n');
        String currentSection = '';
        for (var line in lines) {
          if (line.contains('"unfollowedUsers"')) currentSection = 'unfollowed';
          if (line.contains('"patterns"')) currentSection = 'patterns';
          if (line.contains('"recommendations"'))
            currentSection = 'recommendations';
        }
      }

      return FollowerAnalysisResult(
        unfollowedUsers: _extractUnfollowedUsers(jsonContent),
        patterns: _extractPatterns(jsonContent),
        recommendations: _extractRecommendations(jsonContent),
        rawResponse: content,
      );
    } catch (e) {
      // Fallback: return raw content as single insight
      return FollowerAnalysisResult(
        unfollowedUsers: [],
        patterns: [
          {
            'pattern': 'Analysis Complete',
            'description': content.length > 200
                ? '${content.substring(0, 200)}...'
                : content,
            'severity': 'info',
          },
        ],
        recommendations: [],
        rawResponse: content,
      );
    }
  }

  /// Extract unfollowed users from the analysis response
  List<Map<String, dynamic>> _extractUnfollowedUsers(String content) {
    final users = <Map<String, dynamic>>[];
    final regex = RegExp(
      r'"username"\s*:\s*"([^"]+)"[^}]*"displayName"\s*:\s*"([^"]+)"[^}]*"reason"\s*:\s*"([^"]+)"',
    );
    final matches = regex.allMatches(content);

    for (var match in matches) {
      users.add({
        'username': match.group(1) ?? '',
        'displayName': match.group(2) ?? '',
        'reason': match.group(3) ?? '',
      });
    }

    return users;
  }

  /// Extract patterns from the analysis response
  List<Map<String, dynamic>> _extractPatterns(String content) {
    final patterns = <Map<String, dynamic>>[];
    final regex = RegExp(
      r'"pattern"\s*:\s*"([^"]+)"[^}]*"description"\s*:\s*"([^"]+)"[^}]*"severity"\s*:\s*"([^"]+)"',
    );
    final matches = regex.allMatches(content);

    for (var match in matches) {
      patterns.add({
        'pattern': match.group(1) ?? '',
        'description': match.group(2) ?? '',
        'severity': match.group(3) ?? 'medium',
      });
    }

    return patterns;
  }

  /// Extract recommendations from the analysis response
  List<Map<String, dynamic>> _extractRecommendations(String content) {
    final recommendations = <Map<String, dynamic>>[];
    final regex = RegExp(
      r'"category"\s*:\s*"([^"]+)"[^}]*"suggestion"\s*:\s*"([^"]+)"[^}]*"impact"\s*:\s*"([^"]+)"',
    );
    final matches = regex.allMatches(content);

    for (var match in matches) {
      recommendations.add({
        'category': match.group(1) ?? '',
        'suggestion': match.group(2) ?? '',
        'impact': match.group(3) ?? 'medium',
      });
    }

    return recommendations;
  }
}

/// Result of follower pattern analysis
class FollowerAnalysisResult {
  final List<Map<String, dynamic>> unfollowedUsers;
  final List<Map<String, dynamic>> patterns;
  final List<Map<String, dynamic>> recommendations;
  final String rawResponse;

  FollowerAnalysisResult({
    required this.unfollowedUsers,
    required this.patterns,
    required this.recommendations,
    required this.rawResponse,
  });
}

/// OpenAI Exception
class OpenAIException implements Exception {
  final int statusCode;
  final String message;

  OpenAIException({required this.statusCode, required this.message});

  @override
  String toString() => 'OpenAIException: $statusCode - $message';
}
