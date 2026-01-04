import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Individual follower card widget with rich interaction support
///
/// Features:
/// - Profile image with verification badge
/// - Username and display name
/// - Follow date and mutual connection indicator
/// - Engagement level indicator
/// - Multi-select checkbox
/// - Tap and long-press gestures
class FollowerCardWidget extends StatelessWidget {
  final Map<String, dynamic> follower;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FollowerCardWidget({
    super.key,
    required this.follower,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final followDate = follower["followDate"] as DateTime;
    final formattedDate = DateFormat('MMM dd, yyyy').format(followDate);
    final isMutual = follower["isMutual"] as bool;
    final isVerified = follower["isVerified"] as bool;
    final engagementLevel = follower["engagementLevel"] as String;
    final followerCount = follower["followerCount"] as int;

    return InkWell(
      onTap: () {
        if (isMultiSelectMode) {
          onTap();
        } else {
          // Navigate to profile detail screen
          Navigator.pushNamed(
            context,
            AppRoutes.profileDetail,
            arguments: follower,
          );
        }
      },
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Multi-select checkbox
            if (isMultiSelectMode) ...[
              Checkbox(value: isSelected, onChanged: (_) => onTap()),
              SizedBox(width: 2.w),
            ],

            // Profile image with verification badge
            Stack(
              children: [
                Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: follower["profileImage"] as String,
                      width: 15.w,
                      height: 15.w,
                      fit: BoxFit.cover,
                      semanticLabel: follower["semanticLabel"] as String,
                    ),
                  ),
                ),
                if (isVerified)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: CustomIconWidget(
                        iconName: Icons.verified.codePoint.toString(),
                        color: theme.colorScheme.onPrimary,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: 3.w),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          follower["displayName"] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMutual) ...[
                        SizedBox(width: 1.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Mutual',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    follower["username"] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: Icons.calendar_today.codePoint.toString(),
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Followed $formattedDate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Engagement indicator and follower count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getEngagementColor(
                      engagementLevel,
                      theme,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: Icons.trending_up.codePoint.toString(),
                        size: 12,
                        color: _getEngagementColor(engagementLevel, theme),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        engagementLevel.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getEngagementColor(engagementLevel, theme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _formatFollowerCount(followerCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getEngagementColor(String level, ThemeData theme) {
    switch (level) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatFollowerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M followers';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K followers';
    } else {
      return '$count followers';
    }
  }
}
