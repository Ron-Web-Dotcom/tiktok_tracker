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

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String permissions = '/permissions-screen';
  static const String dashboard = '/dashboard-screen';
  static const String splash = '/splash-screen';
  static const String profileDetail = '/profile-detail-screen';
  static const String login = '/login-screen';
  static const String followingList = '/following-list-screen';
  static const String followersList = '/followers-list-screen';
  static const String analytics = '/analytics-screen';
  static const String notifications = '/notifications-screen';

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
    // TODO: Add your other routes here
  };
}
