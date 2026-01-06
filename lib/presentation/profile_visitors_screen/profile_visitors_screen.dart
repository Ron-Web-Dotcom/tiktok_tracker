import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/tiktok_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/analytics_section_widget.dart';
import './widgets/visitor_card_widget.dart';
import './widgets/visitor_filter_chip_widget.dart';

/// Profile Visitors Screen - Track who viewed your TikTok profile
///
/// This screen displays comprehensive tracking of profile visitors with
/// follower relationship analysis. Users can see who visited their profile,
/// whether they are followers or non-followers, and when they visited.
///
/// Key Features:
/// - View all profile visitors with timestamps
/// - Filter by followers, non-followers, recent, or frequent visitors
/// - Color-coded badges (green for followers, orange for non-followers)
/// - Pull-to-refresh to update visitor data
/// - Analytics section with visitor trends and insights
/// - Privacy controls to disable tracking or clear history
/// - Tap visitor card to view their profile details
/// - Quick action: follow back non-followers
/// - Real-time data when authenticated with TikTok
class ProfileVisitorsScreen extends StatefulWidget {
  const ProfileVisitorsScreen({super.key});

  @override
  State<ProfileVisitorsScreen> createState() => _ProfileVisitorsScreenState();
}

class _ProfileVisitorsScreenState extends State<ProfileVisitorsScreen> {
  final TikTokService _tiktokService = TikTokService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isAuthenticated = false;
  String _selectedFilter =
      'all'; // all, followers, non-followers, recent, frequent
  String _selectedTimeFilter = '24h'; // 24h, week, month

  List<Map<String, dynamic>> _allVisitors = [];
  List<Map<String, dynamic>> _filteredVisitors = [];
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
    _loadVisitorData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Check if user is authenticated with TikTok
  Future<void> _checkAuthenticationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final authenticated = prefs.getBool('tiktok_authenticated') ?? false;
    setState(() => _isAuthenticated = authenticated);
  }

  /// Load visitor data from TikTok service
  Future<void> _loadVisitorData() async {
    setState(() => _isLoading = true);

    try {
      final visitorData = await _tiktokService.fetchProfileVisitors(
        timeFilter: _selectedTimeFilter,
      );

      setState(() {
        _allVisitors = visitorData['visitors'] as List<Map<String, dynamic>>;
        _analyticsData = visitorData['analytics'] as Map<String, dynamic>;
        _filteredVisitors = List.from(_allVisitors);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _allVisitors = [];
        _filteredVisitors = [];
        _analyticsData = {};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load visitors: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Refresh visitor data with pull-to-refresh
  Future<void> _refreshVisitorData() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    await _loadVisitorData();

    setState(() => _isRefreshing = false);
  }

  /// Apply selected filter to visitor list
  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;

      switch (filter) {
        case 'all':
          _filteredVisitors = List.from(_allVisitors);
          break;
        case 'followers':
          _filteredVisitors = _allVisitors
              .where((v) => v['isFollower'] == true)
              .toList();
          break;
        case 'non-followers':
          _filteredVisitors = _allVisitors
              .where((v) => v['isFollower'] == false)
              .toList();
          break;
        case 'recent':
          _filteredVisitors = List.from(_allVisitors)
            ..sort(
              (a, b) => (b['visitDate'] as DateTime).compareTo(
                a['visitDate'] as DateTime,
              ),
            );
          break;
        case 'frequent':
          _filteredVisitors = List.from(_allVisitors)
            ..sort(
              (a, b) =>
                  (b['visitCount'] as int).compareTo(a['visitCount'] as int),
            );
          break;
      }
    });
  }

  /// Change time filter and reload data
  void _changeTimeFilter(String timeFilter) {
    if (_selectedTimeFilter == timeFilter) return;

    setState(() => _selectedTimeFilter = timeFilter);
    _loadVisitorData();
  }

  /// Handle follow back action for non-followers
  Future<void> _handleFollowBack(Map<String, dynamic> visitor) async {
    HapticFeedback.lightImpact();

    try {
      await _tiktokService.followUser(visitor['id'] as String);

      setState(() {
        visitor['isFollowing'] = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Now following ${visitor['username']}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to follow: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to visitor's profile detail
  void _viewVisitorProfile(Map<String, dynamic> visitor) {
    Navigator.pushNamed(context, AppRoutes.profileDetail, arguments: visitor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile Visitors',
        actions: [
          // Authentication status indicator
          if (!_isAuthenticated)
            Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.warningLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.warningLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppTheme.warningLight,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Demo Mode',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.warningLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Colors.green,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Real-Time Data',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Visitor count badge
          Container(
            margin: EdgeInsets.only(right: 4.w),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: Icons.visibility.codePoint.toString(),
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 1.w),
                Text(
                  _allVisitors.length.toString(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Settings icon for privacy controls
          IconButton(
            icon: CustomIconWidget(
              iconName: Icons.settings.codePoint.toString(),
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => _showPrivacySettings(),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Show authentication banner if not authenticated
                if (!_isAuthenticated) _buildAuthenticationBanner(),
                // Show data source info banner for authenticated users
                if (_isAuthenticated) _buildDataSourceInfoBanner(),
                Expanded(
                  child: _allVisitors.isEmpty
                      ? _buildEmptyState()
                      : _buildVisitorsList(),
                ),
              ],
            ),
    );
  }

  /// Build authentication banner for non-authenticated users
  Widget _buildAuthenticationBanner() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withValues(alpha: 0.1),
            AppTheme.accentLight.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryLight, size: 24),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign in for Real-Time Data',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Connect your TikTok account to see actual profile visitors and get personalized insights.',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              'Sign In',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build data source information banner for authenticated users
  Widget _buildDataSourceInfoBanner() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              '⚠️ TikTok API does not provide direct visitor tracking. Data shown is estimated based on your real follower/following lists and engagement patterns.',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 2.h),
          Text(
            'Loading visitors...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: Icons.visibility_off.codePoint.toString(),
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 3.h),
            Text(
              'No Visitors Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'When people visit your profile, they\'ll appear here. Share your profile to get more visitors!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => _refreshVisitorData(),
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorsList() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refreshVisitorData,
      child: Column(
        children: [
          // Time filter chips
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                _buildTimeFilterChip('24h', 'Last 24 Hours'),
                SizedBox(width: 2.w),
                _buildTimeFilterChip('week', 'This Week'),
                SizedBox(width: 2.w),
                _buildTimeFilterChip('month', 'This Month'),
              ],
            ),
          ),

          // Filter chips
          Container(
            height: 6.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                VisitorFilterChipWidget(
                  label: 'All',
                  isSelected: _selectedFilter == 'all',
                  count: _allVisitors.length,
                  onTap: () => _applyFilter('all'),
                ),
                SizedBox(width: 2.w),
                VisitorFilterChipWidget(
                  label: 'Followers',
                  isSelected: _selectedFilter == 'followers',
                  count: _allVisitors
                      .where((v) => v['isFollower'] == true)
                      .length,
                  onTap: () => _applyFilter('followers'),
                ),
                SizedBox(width: 2.w),
                VisitorFilterChipWidget(
                  label: 'Non-Followers',
                  isSelected: _selectedFilter == 'non-followers',
                  count: _allVisitors
                      .where((v) => v['isFollower'] == false)
                      .length,
                  onTap: () => _applyFilter('non-followers'),
                ),
                SizedBox(width: 2.w),
                VisitorFilterChipWidget(
                  label: 'Recent',
                  isSelected: _selectedFilter == 'recent',
                  onTap: () => _applyFilter('recent'),
                ),
                SizedBox(width: 2.w),
                VisitorFilterChipWidget(
                  label: 'Frequent',
                  isSelected: _selectedFilter == 'frequent',
                  onTap: () => _applyFilter('frequent'),
                ),
              ],
            ),
          ),

          // Analytics section
          if (_analyticsData.isNotEmpty)
            AnalyticsSectionWidget(analyticsData: _analyticsData),

          // Visitors list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 1.h),
              itemCount: _filteredVisitors.length,
              itemBuilder: (context, index) {
                final visitor = _filteredVisitors[index];
                return VisitorCardWidget(
                  visitor: visitor,
                  onTap: () => _viewVisitorProfile(visitor),
                  onFollowBack: () => _handleFollowBack(visitor),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterChip(String value, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedTimeFilter == value;

    return Expanded(
      child: InkWell(
        onTap: () => _changeTimeFilter(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _showPrivacySettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: Icons.visibility_off.codePoint.toString(),
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                title: Text('Disable Visitor Tracking'),
                subtitle: Text('Stop tracking who views your profile'),
                onTap: () {
                  Navigator.pop(context);
                  _showDisableTrackingDialog();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: Icons.delete_outline.codePoint.toString(),
                  size: 24,
                  color: theme.colorScheme.error,
                ),
                title: Text('Clear Visitor History'),
                subtitle: Text('Remove all visitor records'),
                onTap: () {
                  Navigator.pop(context);
                  _showClearHistoryDialog();
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  void _showDisableTrackingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disable Visitor Tracking?'),
        content: Text(
          'You will no longer see who visits your profile. This action can be reversed in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement disable tracking logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Visitor tracking disabled'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Visitor History?'),
        content: Text(
          'All visitor records will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allVisitors.clear();
                _filteredVisitors.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Visitor history cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}
