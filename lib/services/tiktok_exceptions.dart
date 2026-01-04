/// Custom exceptions for TikTok API operations
/// Provides detailed error information for better error handling

/// Base exception for all TikTok API errors
class TikTokException implements Exception {
  final int statusCode;
  final String message;

  TikTokException({required this.statusCode, required this.message});

  @override
  String toString() => 'TikTokException ($statusCode): $message';
}

/// Exception thrown when rate limit is exceeded
class TikTokRateLimitException implements Exception {
  final String message;
  final Duration retryAfter;

  TikTokRateLimitException({required this.message, required this.retryAfter});

  @override
  String toString() =>
      'TikTokRateLimitException: $message (Retry after ${retryAfter.inSeconds}s)';
}

/// Exception thrown when insufficient API permissions
class TikTokPermissionException implements Exception {
  final String message;

  TikTokPermissionException({required this.message});

  @override
  String toString() => 'TikTokPermissionException: $message';
}

/// Exception thrown when API scope is insufficient
class TikTokScopeException implements Exception {
  final String message;
  final List<String> requiredScopes;
  final List<String> grantedScopes;

  TikTokScopeException({
    required this.message,
    required this.requiredScopes,
    required this.grantedScopes,
  });

  @override
  String toString() =>
      'TikTokScopeException: $message\nRequired: $requiredScopes\nGranted: $grantedScopes';
}
