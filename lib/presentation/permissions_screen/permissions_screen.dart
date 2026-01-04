import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/feature_unlock_indicator_widget.dart';
import './widgets/permission_card_widget.dart';

/// Permissions Screen for TikTok Tracker
/// Requests essential device and TikTok account access permissions
/// with clear value propositions for each requirement
///
/// ⚠️ TikTok API Compliance Notice:
/// This app demonstrates follower tracking concepts using mock data.
/// Production deployment requires:
/// - Approved TikTok Developer account
/// - Proper API scopes (user.info.basic, follower.list)
/// - Compliance with TikTok's Terms of Service
/// - Rate limiting (max 100 requests/minute)
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  // Permission states
  final Map<String, bool> _permissionStates = {
    'tiktok_data': false,
    'notifications': false,
    'background_refresh': false,
    'storage': false,
    'biometric': false,
    'analytics': false,
  };

  // Expanded states for "Learn More"
  final Map<String, bool> _expandedStates = {
    'tiktok_data': false,
    'notifications': false,
    'background_refresh': false,
    'storage': false,
    'biometric': false,
    'analytics': false,
  };

  int get _requiredPermissionsGranted {
    int count = 0;
    if (_permissionStates['tiktok_data'] == true) count++;
    if (_permissionStates['notifications'] == true) count++;
    if (_permissionStates['background_refresh'] == true) count++;
    if (_permissionStates['storage'] == true) count++;
    return count;
  }

  bool get _canContinue => _requiredPermissionsGranted == 4;

  @override
  void initState() {
    super.initState();
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    // Auto-approve notifications
    final notificationStatus = await Permission.notification.request();

    // Storage doesn't need permission on modern Android/iOS for app-specific storage
    // Using shared_preferences which doesn't require permission
    final prefs = await SharedPreferences.getInstance();
    final storageWorking =
        prefs.getString('storage_test') != null || await _testStorage();

    setState(() {
      _permissionStates['notifications'] = notificationStatus.isGranted;
      _permissionStates['storage'] = storageWorking;
    });
  }

  Future<bool> _testStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('storage_test', 'working');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _requestPermission(String permissionKey) async {
    HapticFeedback.lightImpact();

    bool granted = false;

    switch (permissionKey) {
      case 'tiktok_data':
        // Show compliance notice before authentication
        final shouldContinue = await _showTikTokAuthDialog();
        if (!shouldContinue) return;

        // Mark TikTok data permission as granted (already authenticated via login)
        final prefs = await SharedPreferences.getInstance();
        final isAuthenticated = prefs.getBool('tiktok_authenticated') ?? false;

        if (isAuthenticated) {
          // User already logged in, just grant permission
          granted = true;
        } else {
          // Navigate to login screen for TikTok authentication
          Navigator.pushReplacementNamed(context, '/login-screen');
          return;
        }
        break;
      case 'notifications':
        final status = await Permission.notification.request();
        granted = status.isGranted;
        if (status.isPermanentlyDenied) {
          _showPermissionDeniedDialog('Notifications');
        }
        break;
      case 'background_refresh':
        // iOS-specific, simulated for cross-platform
        granted = true;
        break;
      case 'storage':
        // Use shared_preferences which doesn't require permission
        granted = await _testStorage();
        if (!granted) {
          _showStorageErrorDialog();
        }
        break;
      case 'biometric':
        // Optional permission
        granted = true;
        break;
      case 'analytics':
        // Optional permission
        granted = true;
        break;
    }

    setState(() {
      _permissionStates[permissionKey] = granted;
    });
  }

  Future<bool> _showTikTokAuthDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('TikTok Data Access'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This app will request access to:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Your basic profile information'),
                  const Text('• Your public follower list'),
                  const Text('• Your public following list'),
                  const SizedBox(height: 16),
                  const Text(
                    'Data Usage & Privacy:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Data is cached locally on your device'),
                  const Text('• No data is shared with third parties'),
                  const Text('• You can revoke access anytime'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      '⚠️ Note: This app uses TikTok\'s official API with rate limits (100 requests/minute). Some features may be limited based on TikTok\'s data access policies.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue to Login'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showStorageErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Issue'),
        content: const Text(
          'Unable to access local storage. Please ensure the app has sufficient storage space and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermission('storage');
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: Text(
          '$permissionName permission is required for core functionality. Please enable it in Settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    HapticFeedback.mediumImpact();
    if (_canContinue) {
      // Mark permissions as granted
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('permissions_granted', true);
      });
      Navigator.pushReplacementNamed(context, '/dashboard-screen');
    }
  }

  void _handleSkip() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limited Functionality'),
        content: const Text(
          'Skipping permissions will limit app features:\n\n'
          '• No follower tracking\n'
          '• No unfollow notifications\n'
          '• No offline data access\n\n'
          'You can enable permissions later in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard-screen');
            },
            child: const Text('Continue Anyway'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: Text(
              'Skip',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Grant Permissions',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To provide you with the best experience, we need access to the following:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Required Permissions Section
              Text(
                'REQUIRED PERMISSIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // TikTok Data Access
              PermissionCardWidget(
                iconName: 'people',
                title: 'TikTok Follower Data Access',
                description:
                    'Access your follower and following lists to track changes',
                detailedExplanation:
                    'We need access to your TikTok follower data to monitor who follows you, who you follow, and detect when someone unfollows you. This is the core functionality of the app and enables all tracking features.',
                isRequired: true,
                isGranted: _permissionStates['tiktok_data'] ?? false,
                isExpanded: _expandedStates['tiktok_data'] ?? false,
                onToggle: () => _requestPermission('tiktok_data'),
                onExpandToggle: () {
                  setState(() {
                    _expandedStates['tiktok_data'] =
                        !(_expandedStates['tiktok_data'] ?? false);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Push Notifications
              PermissionCardWidget(
                iconName: 'notifications',
                title: 'Push Notifications',
                description: 'Receive alerts when someone unfollows you',
                detailedExplanation:
                    'Push notifications allow us to instantly alert you when someone unfollows you or when there are significant changes in your follower count. You can customize notification preferences in Settings.',
                isRequired: true,
                isGranted: _permissionStates['notifications'] ?? false,
                isExpanded: _expandedStates['notifications'] ?? false,
                onToggle: () => _requestPermission('notifications'),
                onExpandToggle: () {
                  setState(() {
                    _expandedStates['notifications'] =
                        !(_expandedStates['notifications'] ?? false);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Background App Refresh
              PermissionCardWidget(
                iconName: 'refresh',
                title: 'Background App Refresh',
                description: 'Continuous monitoring of follower changes',
                detailedExplanation:
                    'Background refresh enables the app to check for follower changes even when you\'re not actively using it. This ensures you never miss an unfollow event and keeps your data up-to-date.',
                isRequired: true,
                isGranted: _permissionStates['background_refresh'] ?? false,
                isExpanded: _expandedStates['background_refresh'] ?? false,
                onToggle: () => _requestPermission('background_refresh'),
                onExpandToggle: () {
                  setState(() {
                    _expandedStates['background_refresh'] =
                        !(_expandedStates['background_refresh'] ?? false);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Local Storage
              PermissionCardWidget(
                iconName: 'storage',
                title: 'Local Storage',
                description: 'Cache data for offline access',
                detailedExplanation:
                    'Local storage permission allows us to save your follower data on your device for offline viewing and faster load times. This also enables historical tracking of follower changes over time.',
                isRequired: true,
                isGranted: _permissionStates['storage'] ?? false,
                isExpanded: _expandedStates['storage'] ?? false,
                onToggle: () => _requestPermission('storage'),
                onExpandToggle: () {
                  setState(() {
                    _expandedStates['storage'] =
                        !(_expandedStates['storage'] ?? false);
                  });
                },
              ),
              const SizedBox(height: 24),

              // Optional Permissions Section
              Text(
                'OPTIONAL PERMISSIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Biometric Authentication
              PermissionCardWidget(
                iconName: 'fingerprint',
                title: 'Biometric Authentication',
                description: 'Secure app access with fingerprint or Face ID',
                detailedExplanation:
                    'Enable biometric authentication to add an extra layer of security to your account. This prevents unauthorized access to your follower data and analytics.',
                isRequired: false,
                isGranted: _permissionStates['biometric'] ?? false,
                isExpanded: _expandedStates['biometric'] ?? false,
                onToggle: () => _requestPermission('biometric'),
                onExpandToggle: () {
                  setState(() {
                    _expandedStates['biometric'] =
                        !(_expandedStates['biometric'] ?? false);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Analytics Sharing
              PermissionCardWidget(
                iconName: 'analytics',
                title: 'Analytics Sharing',
                description: 'Help us improve the app with usage data',
                detailedExplanation:
                    'Share anonymous usage analytics to help us understand how you use the app and improve features. No personal data or follower information is shared.',
                isRequired: false,
                isGranted: _permissionStates['analytics'] ?? false,
                isExpanded: _expandedStates['analytics'] ?? false,
                onToggle: () => _requestPermission('analytics'),
                onExpandToggle: () {
                  setState(() {
                    _expandedStates['analytics'] =
                        !(_expandedStates['analytics'] ?? false);
                  });
                },
              ),
              const SizedBox(height: 24),

              // Feature Unlock Indicators
              Text(
                'FEATURES YOU\'LL UNLOCK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              FeatureUnlockIndicatorWidget(
                features: const [
                  {
                    'icon': 'trending_up',
                    'title': 'Real-time Follower Tracking',
                    'description': 'Monitor follower changes as they happen',
                  },
                  {
                    'icon': 'notifications_active',
                    'title': 'Instant Unfollow Alerts',
                    'description':
                        'Get notified immediately when someone unfollows',
                  },
                  {
                    'icon': 'history',
                    'title': 'Historical Data Analysis',
                    'description': 'View follower trends over time',
                  },
                  {
                    'icon': 'offline_bolt',
                    'title': 'Offline Access',
                    'description': 'View cached data without internet',
                  },
                ],
              ),
              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canContinue ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canContinue
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    foregroundColor: _canContinue
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    elevation: _canContinue ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _canContinue
                            ? 'Continue'
                            : 'Grant ${4 - _requiredPermissionsGranted} More Permissions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _canContinue
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.38,
                                ),
                        ),
                      ),
                      if (_canContinue) ...[
                        const SizedBox(width: 8),
                        CustomIconWidget(
                          iconName: 'arrow_forward',
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomIconWidget(
                      iconName: 'lock',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Privacy Matters',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We only use your data to provide tracking services. Your information is never shared with third parties.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
