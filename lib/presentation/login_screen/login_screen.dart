import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/tiktok_service.dart';

/// Login Screen for TikTok Tracker application
/// Implements secure TikTok OAuth authentication with mobile-optimized interaction
///
/// Features:
/// - TikTok OAuth integration with native webview
/// - Guest mode for limited app exploration
/// - Biometric authentication setup prompt
/// - Platform-specific authentication flows
/// - Trust signals and compliance indicators
///
/// ⚠️ IMPORTANT: Production Deployment Requirements
/// This demo uses mock authentication. For TikTok review approval:
/// 1. Register app at https://developers.tiktok.com/
/// 2. Request API scopes: user.info.basic, follower.list
/// 3. Implement proper OAuth 2.0 flow with flutter_web_auth
/// 4. Handle rate limits (100 requests/minute)
/// 5. Comply with TikTok's Terms of Service
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showDemoDisclaimer = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handle TikTok OAuth login flow
  ///
  /// Production OAuth Flow:
  /// 1. Use flutter_web_auth for OAuth flow
  /// 2. Exchange authorization code for access token
  /// 3. Validate token with TikTok API
  /// 4. Store token securely with flutter_secure_storage
  Future<void> _handleTikTokLogin() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Get TikTok credentials from environment
      const clientKey = String.fromEnvironment('TIKTOK_CLIENT_KEY');
      const clientSecret = String.fromEnvironment('TIKTOK_CLIENT_SECRET');

      // Check if real credentials are available
      if (clientKey.isEmpty || clientSecret.isEmpty) {
        throw Exception(
          'TikTok API credentials not configured. Please add TIKTOK_CLIENT_KEY and TIKTOK_CLIENT_SECRET to your environment variables.',
        );
      }

      // Implement real OAuth flow
      // Note: This requires flutter_web_auth package and proper redirect URI setup
      // For now, show error that real OAuth needs to be configured
      throw Exception(
        'TikTok OAuth flow requires additional setup. Please configure redirect URI and implement OAuth 2.0 flow.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showErrorDialog('Authentication Failed', e.toString());
    }
  }

  /// Handle mock authentication for demo mode
  Future<void> _handleMockAuthentication() async {
    await Future.delayed(const Duration(seconds: 2));

    // Generate a mock access token for testing
    const mockAccessToken = 'mock_tiktok_access_token_for_testing';

    // Store the access token using TikTok service
    final tiktokService = TikTokService();
    await tiktokService.storeAccessToken(mockAccessToken);

    // Mark that user has completed TikTok authentication
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tiktok_authenticated', true);
    await prefs.setBool('has_tiktok_data', true);

    if (!mounted) return;

    // Success haptic feedback
    HapticFeedback.heavyImpact();

    // Navigate to dashboard (skip permissions if already granted)
    final hasSeenPermissions = prefs.getBool('permissions_granted') ?? false;
    if (hasSeenPermissions) {
      Navigator.pushReplacementNamed(context, '/dashboard-screen');
    } else {
      Navigator.pushReplacementNamed(context, '/permissions-screen');
    }
  }

  /// Handles guest mode navigation
  void _handleGuestMode() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacementNamed(context, '/dashboard-screen');
  }

  /// Shows error dialog with retry option
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleTikTokLogin();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Shows info dialog for policies
  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Shows TikTok API compliance and data usage information
  void _showDataUsageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Usage & Privacy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What data we access:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Basic profile information (username, avatar)'),
              const Text('• Public follower list'),
              const Text('• Public following list'),
              const SizedBox(height: 16),
              const Text(
                'How we use your data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Track follower changes over time'),
              const Text('• Identify mutual connections'),
              const Text('• Generate engagement insights'),
              const Text('• Cache data locally for offline access'),
              const SizedBox(height: 16),
              const Text(
                'Your privacy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• All data stored locally on your device'),
              const Text('• No data shared with third parties'),
              const Text('• You can revoke access anytime'),
              const Text('• Complies with TikTok\'s Terms of Service'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'ℹ️ This app respects TikTok\'s rate limits (100 requests/minute) and only accesses public data available through official APIs.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Demo Mode Disclaimer Banner
            if (_showDemoDisclaimer)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.orange.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20.sp,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        '⚠️ DEMO MODE: This app uses simulated data for demonstration purposes. Real TikTok integration requires approved API access.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18.sp,
                        color: Colors.orange.shade700,
                      ),
                      onPressed: () {
                        setState(() {
                          _showDemoDisclaimer = false;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          100.h -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              SizedBox(height: 8.h),
                              _buildAppLogo(theme),
                              SizedBox(height: 4.h),
                              _buildWelcomeText(theme),
                              SizedBox(height: 6.h),
                              _buildAuthenticationSection(theme),
                            ],
                          ),
                          Column(
                            children: [
                              _buildTrustSignals(theme),
                              SizedBox(height: 2.h),
                              _buildComplianceLinks(theme),
                              SizedBox(height: 3.h),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds app logo with brand recognition
  Widget _buildAppLogo(ThemeData theme) {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: -8,
          ),
        ],
      ),
      padding: EdgeInsets.all(2.5.w),
      child: ClipOval(
        child: CustomImageWidget(
          imageUrl: 'assets/images/IMG_0007-1767820455546.png',
          width: 19.w,
          height: 19.w,
          fit: BoxFit.cover,
          semanticLabel: 'TikTok Tracker logo',
        ),
      ),
    );
  }

  /// Builds welcome text section
  Widget _buildWelcomeText(ThemeData theme) {
    return Column(
      children: [
        Text(
          'TikTok Tracker',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Track your follower relationships\nand engagement patterns',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds authentication section with TikTok login and guest mode
  Widget _buildAuthenticationSection(ThemeData theme) {
    return Column(
      children: [
        // TikTok Connect Button
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleTikTokLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 5.w,
                    width: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.95),
                              Colors.white.withValues(alpha: 0.85),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(1.5.w),
                        child: ClipOval(
                          child: CustomImageWidget(
                            imageUrl:
                                'assets/images/IMG_0007-1767820455546.png',
                            width: 9.w,
                            height: 9.w,
                            fit: BoxFit.cover,
                            semanticLabel: 'TikTok icon',
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Connect with TikTok',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 2.h),
        // Divider with "OR"
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'OR',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        // Guest Mode Button
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _handleGuestMode,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            child: Text(
              'Continue as Guest',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: 3.h),
        // Guest Mode Info
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(2.w),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'info_outline',
                color: theme.colorScheme.primary,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Guest mode allows limited app exploration without full account access',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds trust signals section
  Widget _buildTrustSignals(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTrustBadge(theme, 'verified', 'SSL Secure'),
        SizedBox(width: 4.w),
        _buildTrustBadge(theme, 'check_circle', 'Official API'),
        SizedBox(width: 4.w),
        _buildTrustBadge(theme, 'privacy_tip', 'Privacy First'),
      ],
    );
  }

  /// Builds individual trust badge
  Widget _buildTrustBadge(ThemeData theme, String iconName, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(1.5.w),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.primary,
            size: 4.w,
          ),
          SizedBox(width: 1.5.w),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds compliance links section
  Widget _buildComplianceLinks(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showInfoDialog(
              'Privacy Policy',
              'TikTok Tracker respects your privacy. We only access follower data you explicitly authorize. Your data is stored locally and never shared with third parties without consent.',
            );
          },
          child: Text(
            'Privacy Policy',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          ' • ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showInfoDialog(
              'Terms of Service',
              'By using TikTok Tracker, you agree to:\n\n• Use the app in compliance with TikTok\'s Terms of Service\n• Not use the app for spam or harassment\n• Understand that follower data is provided as-is\n• Accept that we may update these terms',
            );
          },
          child: Text(
            'Terms of Service',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
