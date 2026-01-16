import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

/// Splash Screen for TikTok Tracker application
///
/// Provides branded app launch experience while initializing TikTok API connections
/// and determining user authentication status. Handles authentication routing,
/// API connectivity checks, and deep link processing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Setup pulse animation for logo
  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse animation loop
    _pulseController.repeat(reverse: true);
  }

  /// Initialize app and perform startup checks
  Future<void> _initializeApp() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
        _showRetry = false;
      });

      // Simulate TikTok OAuth token verification
      await Future.delayed(const Duration(milliseconds: 800));
      final bool hasValidToken = await _verifyTikTokToken();

      // Simulate loading cached follower data
      await Future.delayed(const Duration(milliseconds: 600));
      await _loadCachedData();

      // Simulate API connectivity check
      await Future.delayed(const Duration(milliseconds: 800));
      final bool isApiConnected = await _checkApiConnectivity();

      if (!isApiConnected) {
        throw Exception('Unable to connect to TikTok API');
      }

      // Simulate preparing dashboard analytics
      await Future.delayed(const Duration(milliseconds: 400));
      await _prepareDashboard();

      // Add haptic feedback on completion
      HapticFeedback.lightImpact();

      // Navigate based on authentication status
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 300));

      if (hasValidToken) {
        // Authenticated user - go to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard-screen');
      } else {
        // Check if first-time user
        final bool isFirstTime = await _checkFirstTimeUser();
        if (isFirstTime) {
          Navigator.pushReplacementNamed(context, '/permissions-screen');
        } else {
          Navigator.pushReplacementNamed(context, '/login-screen');
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      // Show retry option after 5 seconds
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _showRetry = true;
        });
      }
    }
  }

  /// Verify TikTok OAuth token validity
  Future<bool> _verifyTikTokToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool('tiktok_authenticated') ?? false;
      final accessToken = prefs.getString('tiktok_access_token');

      // Check if user has valid authentication
      return isAuthenticated && accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Load cached follower data
  Future<void> _loadCachedData() async {
    // Simulate loading cached data from local storage
    // In production, this would load from Hive/SQLite
  }

  /// Check API connectivity
  Future<bool> _checkApiConnectivity() async {
    // Simulate API connectivity check
    // In production, this would ping TikTok API endpoints
    return true;
  }

  /// Prepare dashboard analytics
  Future<void> _prepareDashboard() async {
    // Simulate preparing dashboard data
    // In production, this would process analytics data
  }

  /// Check if user is first-time user
  Future<bool> _checkFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenPermissions = prefs.getBool('permissions_granted') ?? false;
      return !hasSeenPermissions;
    } catch (e) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: theme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildLogo(theme),
                SizedBox(height: 8.h),
                _buildAppName(theme),
                SizedBox(height: 2.h),
                _buildTagline(theme),
                const Spacer(flex: 2),
                _buildLoadingIndicator(theme),
                SizedBox(height: 4.h),
                if (_hasError) _buildErrorMessage(theme),
                if (_showRetry) _buildRetryButton(theme),
                SizedBox(height: 4.h),
                _buildTikTokBadge(theme),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build animated logo
  Widget _buildLogo(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 60,
                  spreadRadius: -10,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: EdgeInsets.all(3.w),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: 'assets/images/IMG_0007-1767820455546.png',
                width: 22.w,
                height: 22.w,
                fit: BoxFit.cover,
                semanticLabel: 'TikTok Tracker app logo',
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build app name
  Widget _buildAppName(ThemeData theme) {
    return Text(
      'TikTok Tracker',
      style: theme.textTheme.headlineLarge?.copyWith(
        color: theme.colorScheme.surface,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build tagline
  Widget _buildTagline(ThemeData theme) {
    return Text(
      'Track Your Follower Journey',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator(ThemeData theme) {
    if (_hasError && _showRetry) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 10.w,
          height: 10.w,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.surface,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          _isInitializing ? 'Initializing...' : 'Loading',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  /// Build error message
  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            size: 6.w,
            color: theme.colorScheme.surface,
          ),
          SizedBox(width: 3.w),
          Flexible(
            child: Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.surface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build retry button
  Widget _buildRetryButton(ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        _initializeApp();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: CustomIconWidget(
        iconName: 'refresh',
        size: 5.w,
        color: theme.colorScheme.primary,
      ),
      label: Text(
        'Retry',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Build TikTok integration badge
  Widget _buildTikTokBadge(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'verified',
            size: 4.w,
            color: theme.colorScheme.surface,
          ),
          SizedBox(width: 2.w),
          Text(
            'Official TikTok Integration',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
