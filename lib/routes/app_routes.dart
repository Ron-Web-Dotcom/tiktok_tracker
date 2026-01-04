import 'package:flutter/material.dart';
import '../presentation/permissions_screen/permissions_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/profile_detail_screen/profile_detail_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/following_list_screen/following_list_screen.dart';
import '../presentation/followers_list_screen/followers_list_screen.dart';
import '../presentation/analytics_screen/analytics_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/privacy_compliance_screen/privacy_compliance_screen.dart';
import '../presentation/alternative_features_screen/alternative_features_screen.dart';

/// Central routing configuration for the TikTok Tracker app
/// This class manages all screen navigation paths
class AppRoutes {
  // Route path constants - used for navigation throughout the app
  static const String initial = '/'; // First screen shown (splash)
  static const String permissions =
      '/permissions-screen'; // TikTok permissions request
  static const String dashboard =
      '/dashboard-screen'; // Main dashboard with metrics
  static const String splash = '/splash-screen'; // App loading screen
  static const String profileDetail =
      '/profile-detail-screen'; // User profile details
  static const String login = '/login-screen'; // TikTok login screen
  static const String followingList =
      '/following-list-screen'; // Accounts you follow
  static const String followersList =
      '/followers-list-screen'; // Your followers
  static const String analytics = '/analytics-screen'; // Analytics and insights
  static const String notifications =
      '/notifications-screen'; // Notifications feed
  static const String privacyCompliance =
      '/privacy-compliance-screen'; // Privacy & Compliance
  static const String alternativeFeatures =
      '/alternative-features-screen'; // Alternative Features

  /// Map of route paths to their corresponding screen widgets
  /// Used by MaterialApp to navigate between screens
  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    permissions: (context) => const PermissionsScreen(),
    dashboard: (context) => const DashboardScreen(),
    splash: (context) => const SplashScreen(),
    profileDetail: (context) => const ProfileDetailScreen(),
    login: (context) => const LoginScreen(),
    followingList: (context) => const FollowingListScreen(),
    followersList: (context) => const FollowersListScreen(),
    analytics: (context) => const AnalyticsScreen(),
    notifications: (context) => const NotificationsScreen(),
    privacyCompliance: (context) => const PrivacyComplianceScreen(),
    alternativeFeatures: (context) => const AlternativeFeaturesScreen(),
  };
}
