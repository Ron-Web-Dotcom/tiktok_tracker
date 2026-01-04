import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Tabbed interface for profile content sections
class ProfileTabsWidget extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileTabsWidget({super.key, required this.userData});

  @override
  State<ProfileTabsWidget> createState() => _ProfileTabsWidgetState();
}

class _ProfileTabsWidgetState extends State<ProfileTabsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (_) => HapticFeedback.lightImpact(),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Activity'),
              Tab(text: 'Mutual'),
              Tab(text: 'Content'),
            ],
          ),
        ),

        // Tab Views
        SizedBox(
          height: 50.h,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context),
              _buildActivityTab(context),
              _buildMutualTab(context),
              _buildContentTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final theme = Theme.of(context);
    final bio = widget.userData["bio"] as String? ?? 'No bio available';
    final joinDate = widget.userData["joinDate"] as DateTime;
    final lastActive = widget.userData["lastActive"] as DateTime;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Section
          Text(
            'Bio',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(bio, style: theme.textTheme.bodyMedium),
          SizedBox(height: 3.h),

          // Account Info
          Text(
            'Account Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          _buildInfoRow(
            context,
            'Joined',
            _formatDate(joinDate),
            Icons.calendar_today,
          ),
          SizedBox(height: 1.h),
          _buildInfoRow(
            context,
            'Last Active',
            _formatRelativeTime(lastActive),
            Icons.access_time,
          ),
          SizedBox(height: 3.h),

          // Engagement Stats
          Text(
            'Engagement Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          _buildStatCard(
            context,
            'Average Likes',
            widget.userData["avgLikes"] as int,
            Icons.thumb_up,
          ),
          SizedBox(height: 1.h),
          _buildStatCard(
            context,
            'Average Comments',
            widget.userData["avgComments"] as int,
            Icons.comment,
          ),
          SizedBox(height: 1.h),
          _buildStatCard(
            context,
            'Average Shares',
            widget.userData["avgShares"] as int,
            Icons.share,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context) {
    final theme = Theme.of(context);
    final activities = widget.userData["activityHistory"] as List;
    final isOwnProfile = widget.userData["isOwnProfile"] as bool? ?? false;

    return activities.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: Icons.history.codePoint.toString(),
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 48,
                ),
                SizedBox(height: 2.h),
                Text(
                  isOwnProfile ? 'No recent activity' : 'No activity history',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: activities.length,
            separatorBuilder: (_, __) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final activity = activities[index] as Map<String, dynamic>;
              return _buildActivityItem(context, activity, isOwnProfile);
            },
          );
  }

  Widget _buildMutualTab(BuildContext context) {
    final theme = Theme.of(context);
    final mutualConnections = widget.userData["mutualConnections"] as List;

    return mutualConnections.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: Icons.people.codePoint.toString(),
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 48,
                ),
                SizedBox(height: 2.h),
                Text(
                  'No mutual connections',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: mutualConnections.length,
            separatorBuilder: (_, __) => Divider(height: 3.h),
            itemBuilder: (context, index) {
              final connection =
                  mutualConnections[index] as Map<String, dynamic>;
              return _buildMutualConnectionItem(context, connection);
            },
          );
  }

  Widget _buildContentTab(BuildContext context) {
    final theme = Theme.of(context);
    final recentPosts = widget.userData["recentPosts"] as List;

    return recentPosts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: Icons.video_library.codePoint.toString(),
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 48,
                ),
                SizedBox(height: 2.h),
                Text(
                  'No recent content',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: EdgeInsets.all(4.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 2.w,
              childAspectRatio: 0.75,
            ),
            itemCount: recentPosts.length,
            itemBuilder: (context, index) {
              final post = recentPosts[index] as Map<String, dynamic>;
              return _buildContentItem(context, post);
            },
          );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CustomIconWidget(
          iconName: icon.codePoint.toString(),
          color: theme.colorScheme.primary,
          size: 20,
        ),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    int value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: icon.codePoint.toString(),
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatNumber(value),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    Map<String, dynamic> activity,
    bool isOwnProfile,
  ) {
    final theme = Theme.of(context);
    final type = activity['type'] as String;
    final timestamp = activity['timestamp'] as DateTime;

    IconData icon;
    String title;
    Color color;

    if (isOwnProfile) {
      // Activity types for own profile
      switch (type) {
        case 'new_follower':
          final user = activity['user'] as Map<String, dynamic>;
          icon = Icons.person_add;
          title =
              '${user['displayName'] ?? user['username']} started following you';
          color = theme.colorScheme.primary;
          break;
        case 'started_following':
          final user = activity['user'] as Map<String, dynamic>;
          icon = Icons.person_add_outlined;
          title =
              'You started following ${user['displayName'] ?? user['username']}';
          color = Colors.blue;
          break;
        default:
          icon = Icons.info;
          title = 'Activity';
          color = theme.colorScheme.onSurfaceVariant;
      }
    } else {
      // Activity types for other users' profiles
      switch (type) {
        case 'follow':
          icon = Icons.person_add;
          title = 'Started following you';
          color = theme.colorScheme.primary;
          break;
        case 'mutual':
          icon = Icons.people;
          title = 'Became mutual connection';
          color = Colors.green;
          break;
        case 'unfollow':
          icon = Icons.person_remove;
          title = 'Unfollowed you';
          color = theme.colorScheme.error;
          break;
        default:
          icon = Icons.info;
          title = 'Activity';
          color = theme.colorScheme.onSurfaceVariant;
      }
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: icon.codePoint.toString(),
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _formatRelativeTime(timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualConnectionItem(
    BuildContext context,
    Map<String, dynamic> connection,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(
          context,
          AppRoutes.profileDetail,
          arguments: connection,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: connection['profileImage'] as String,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                semanticLabel: connection['semanticLabel'] as String,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        connection['displayName'] as String,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (connection['isVerified'] as bool) ...[
                      SizedBox(width: 1.w),
                      CustomIconWidget(
                        iconName: Icons.verified.codePoint.toString(),
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Text(
                  connection['username'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: Icons.chevron_right.codePoint.toString(),
            color: theme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildContentItem(BuildContext context, Map<String, dynamic> post) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        // Navigate to content detail
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: CustomImageWidget(
                  imageUrl: post["thumbnail"] as String,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: post["semanticLabel"] as String,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'favorite',
                    color: theme.colorScheme.error,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatCount(post["likes"] as int),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
