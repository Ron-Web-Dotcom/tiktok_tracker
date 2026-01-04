import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Following card widget displaying user information with engagement metrics
class FollowingCardWidget extends StatelessWidget {
  final Map<String, dynamic> following;
  final bool isSelected;
  final bool isBulkSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onUnfollow;

  const FollowingCardWidget({
    super.key,
    required this.following,
    required this.isSelected,
    required this.isBulkSelectionMode,
    required this.onTap,
    required this.onUnfollow,
  });

  Color _getEngagementColor(BuildContext context, int score) {
    final theme = Theme.of(context);
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return theme.colorScheme.error;
  }

  String _getEngagementLabel(int score) {
    if (score >= 70) return 'High';
    if (score >= 50) return 'Medium';
    return 'Low';
  }

  String _formatLastInteraction(DateTime lastInteraction) {
    final now = DateTime.now();
    final difference = now.difference(lastInteraction);

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final followsBack = following["followsBack"] as bool;
    final engagementScore = following["engagementScore"] as int;
    final lastInteraction = following["lastInteraction"] as DateTime;
    final mutualConnections = following["mutualConnections"] as int;
    final isActive = following["isActive"] as bool;

    return Slidable(
      key: ValueKey(following["id"]),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                context,
                AppRoutes.profileDetail,
                arguments: following,
              );
            },
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              _showUnfollowDialog(context);
            },
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.person_remove,
            label: 'Unfollow',
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: 2.h),
        child: InkWell(
          onTap: () {
            if (isBulkSelectionMode) {
              onTap();
            } else {
              // Navigate to profile detail screen
              Navigator.pushNamed(
                context,
                AppRoutes.profileDetail,
                arguments: following,
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                // Selection Checkbox
                if (isBulkSelectionMode) ...[
                  Checkbox(value: isSelected, onChanged: (_) => onTap()),
                  SizedBox(width: 2.w),
                ],

                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: ClipOval(
                        child: CustomImageWidget(
                          imageUrl: following["avatar"] as String,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          semanticLabel: following["semanticLabel"] as String,
                        ),
                      ),
                    ),
                    if (!isActive)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(width: 3.w),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              following["displayName"] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!followsBack)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Not Following Back',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        following["username"] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          // Engagement Score
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getEngagementColor(
                                context,
                                engagementScore,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: 'trending_up',
                                  color: _getEngagementColor(
                                    context,
                                    engagementScore,
                                  ),
                                  size: 12,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  _getEngagementLabel(engagementScore),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _getEngagementColor(
                                      context,
                                      engagementScore,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 2.w),

                          // Last Interaction
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 12,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _formatLastInteraction(lastInteraction),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: 2.w),

                          // Mutual Connections
                          if (mutualConnections > 0) ...[
                            CustomIconWidget(
                              iconName: 'people',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 12,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '$mutualConnections mutual',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Button
                if (!isBulkSelectionMode)
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'more_vert',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => _showOptionsBottomSheet(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUnfollowDialog(BuildContext context) {
    final theme = Theme.of(context);
    final mutualConnections = following["mutualConnections"] as int;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfollow User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to unfollow ${following["username"]}?'),
            if (mutualConnections > 0) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'You have $mutualConnections mutual connections',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUnfollow();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 1.h),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'person',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/profile-detail-screen',
                    arguments: following,
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'person_remove',
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                title: Text(
                  'Unfollow',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showUnfollowDialog(context);
                },
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
    );
  }
}
