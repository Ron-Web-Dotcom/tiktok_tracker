import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/cache_service.dart';
import '../../services/tiktok_service.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_tabs_widget.dart';
import './widgets/relationship_status_widget.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isOwnProfile = true;
  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _userData = {};
  final TikTokService _tiktokService = TikTokService();
  final CacheService _cacheService = CacheService();

  @override
  void initState() {
    super.initState();
    // Delay loading to get arguments from context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Get user data from navigation arguments
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args != null && args is Map<String, dynamic>) {
        // Viewing another user's profile (from follower/following list)
        _isOwnProfile = false;
        _userData = Map<String, dynamic>.from(args);

        // Ensure all required fields exist with defaults
        _userData.putIfAbsent('username', () => '@user');
        _userData.putIfAbsent('displayName', () => 'User');
        _userData.putIfAbsent(
          'profileImage',
          () => _userData['avatar'] ?? 'https://via.placeholder.com/150',
        );
        _userData.putIfAbsent('semanticLabel', () => 'User profile picture');
        _userData.putIfAbsent('isVerified', () => false);
        _userData.putIfAbsent(
          'followersCount',
          () => _userData['followerCount'] ?? 0,
        );
        _userData.putIfAbsent('followingCount', () => 0);
        _userData.putIfAbsent('likesCount', () => 0);
        _userData.putIfAbsent(
          'isFollowing',
          () => _userData['followsBack'] ?? false,
        );
        _userData.putIfAbsent(
          'followsYou',
          () => _userData['isMutual'] ?? false,
        );
        _userData.putIfAbsent('bio', () => 'No bio available');
        _userData.putIfAbsent(
          'joinDate',
          () => DateTime.now().subtract(const Duration(days: 365)),
        );
        _userData.putIfAbsent(
          'lastActive',
          () => _userData['lastInteraction'] ?? DateTime.now(),
        );
        _userData.putIfAbsent('avgLikes', () => 0);
        _userData.putIfAbsent('avgComments', () => 0);
        _userData.putIfAbsent('avgShares', () => 0);
        _userData.putIfAbsent('activityHistory', () => []);
        _userData.putIfAbsent('mutualConnections', () => []);
        _userData.putIfAbsent('recentPosts', () => []);
        _userData['isOwnProfile'] = false;
      } else {
        // No arguments - viewing own profile (from bottom navigation)
        _isOwnProfile = true;
        _userData = await _tiktokService.fetchCurrentUserProfile();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e
            .toString()
            .replaceAll('TikTokException', '')
            .replaceAll('Exception:', '')
            .trim();
      });
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Try to load from cache first
      final cachedProfile = await _cacheService.getCachedUserProfile();

      if (cachedProfile != null) {
        if (!mounted) return;
        setState(() {
          _profileData = cachedProfile;
          _isLoading = false;
        });
      }

      // Fetch fresh data from TikTok
      final profile = await _tiktokService.fetchCurrentUserProfile();

      // Cache the profile data
      await _cacheService.cacheUserProfile(profile);

      if (!mounted) return;
      setState(() {
        _profileData = profile;
        _isLoading = false;
      });
    } catch (e) {
      // Use cached data on error
      final cachedProfile = await _cacheService.getCachedUserProfile();
      if (cachedProfile != null) {
        if (!mounted) return;
        setState(() {
          _profileData = cachedProfile;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleFollowToggle() {
    HapticFeedback.mediumImpact();

    setState(() {
      _userData["isFollowing"] = !(_userData["isFollowing"] as bool);
    });

    final isFollowing = _userData["isFollowing"] as bool;
    Fluttertoast.showToast(
      msg: isFollowing
          ? 'You are now following ${_userData["username"]}'
          : 'You unfollowed ${_userData["username"]}',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  void _handleBlock() {
    HapticFeedback.mediumImpact();

    Fluttertoast.showToast(
      msg: '${_userData["username"]} has been blocked',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );

    // Navigate back after blocking
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _handleMessage() {
    HapticFeedback.lightImpact();

    Fluttertoast.showToast(
      msg: 'Messaging feature coming soon',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  void _handleShare() {
    HapticFeedback.lightImpact();

    Share.share(
      'Check out ${_userData["displayName"]}\'s TikTok profile: ${_userData["username"]}',
      subject: 'TikTok Profile',
    );
  }

  void _handleEditProfile() {
    HapticFeedback.lightImpact();

    // Navigate to edit profile screen (to be implemented)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text(
          'Profile editing will allow you to:\n\n'
          '• Update your display name\n'
          '• Change profile picture\n'
          '• Edit bio\n'
          '• Manage privacy settings\n\n'
          'This feature is coming in the next update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleSettings() {
    HapticFeedback.lightImpact();

    // Navigate to settings screen (to be implemented)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text(
          'Settings will include:\n\n'
          '• Notification preferences\n'
          '• Data sync frequency\n'
          '• Privacy controls\n'
          '• Account management\n'
          '• App preferences\n\n'
          'This feature is coming in the next update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If no route to pop, navigate to dashboard
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            }
          },
          tooltip: 'Go back',
        ),
        title: _isLoading
            ? null
            : Text(
                _isOwnProfile
                    ? 'My Profile'
                    : (_userData["username"] as String),
                style: theme.appBarTheme.titleTextStyle,
              ),
        actions: [
          if (!_isLoading && !_hasError)
            if (_isOwnProfile)
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'settings',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: _handleSettings,
                tooltip: 'Settings',
              )
            else
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'share',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: _handleShare,
                tooltip: 'Share profile',
              ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState(context)
          : _hasError
          ? _buildErrorState(context)
          : _buildContent(context),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Profile Image Skeleton
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          SizedBox(height: 2.h),

          // Username Skeleton
          Container(
            width: 40.w,
            height: 2.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 1.h),

          // Display Name Skeleton
          Container(
            width: 30.w,
            height: 2.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 3.h),

          // Stats Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (index) => Column(
                children: [
                  Container(
                    width: 15.w,
                    height: 2.5.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    width: 12.w,
                    height: 1.5.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: theme.colorScheme.error,
              size: 64,
            ),
            SizedBox(height: 3.h),
            Text(
              'Failed to Load Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Unable to fetch profile data. Please check your connection and try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          ProfileHeaderWidget(userData: _userData),

          // Relationship Status & Actions (only for other users' profiles)
          if (!_isOwnProfile)
            RelationshipStatusWidget(
              userData: _userData,
              onFollowToggle: _handleFollowToggle,
              onBlock: _handleBlock,
              onMessage: _handleMessage,
            )
          else
            // Edit Profile button for own profile
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleEditProfile,
                  icon: CustomIconWidget(
                    iconName: 'edit',
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ),

          SizedBox(height: 2.h),

          // Tabbed Content
          ProfileTabsWidget(userData: _userData),
        ],
      ),
    );
  }
}
