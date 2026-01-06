import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

/// Individual visitor card widget displaying visitor information
///
/// Features:
/// - Profile image with verification badge
/// - Username and display name
/// - Visit timestamp and visit count
/// - Follower status badge (green for followers, orange for non-followers)
/// - Follow back button for non-followers
/// - Tap to view visitor's profile
class VisitorCardWidget extends StatelessWidget {
  final Map<String, dynamic> visitor;
  final VoidCallback onTap;
  final VoidCallback onFollowBack;

  const VisitorCardWidget({
    super.key,
    required this.visitor,
    required this.onTap,
    required this.onFollowBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visitDate = visitor['visitDate'] as DateTime;
    final formattedTime = _formatVisitTime(visitDate);
    final isFollower = visitor['isFollower'] as bool;
    final isVerified = visitor['isVerified'] as bool? ?? false;
    final visitCount = visitor['visitCount'] as int? ?? 1;
    final isFollowing = visitor['isFollowing'] as bool? ?? false;
    final isEstimated = visitor['estimatedVisit'] as bool? ?? false;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
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
                      imageUrl: visitor['profileImage'] as String,
                      width: 15.w,
                      height: 15.w,
                      fit: BoxFit.cover,
                      semanticLabel:
                          visitor['semanticLabel'] as String? ??
                          'Visitor profile picture',
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
                      child: Icon(
                        Icons.verified,
                        size: 12,
                        color: theme.colorScheme.onPrimary,
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
                          visitor['displayName'] as String? ??
                              visitor['username'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // Follower status badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: isFollower
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isFollower ? 'Follower' : 'Non-Follower',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isFollower ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Estimated visit indicator
                      if (isEstimated) ...[
                        SizedBox(width: 1.w),
                        Tooltip(
                          message: 'Estimated based on engagement patterns',
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 1.5.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    visitor['username'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        formattedTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (visitCount > 1) ...[
                        SizedBox(width: 2.w),
                        Text(
                          '• $visitCount visits',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Follow back button for non-followers
            if (!isFollower && !isFollowing)
              OutlinedButton(
                onPressed: onFollowBack,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Follow', style: theme.textTheme.labelSmall),
              ),
          ],
        ),
      ),
    );
  }

  String _formatVisitTime(DateTime visitDate) {
    final now = DateTime.now();
    final difference = now.difference(visitDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(visitDate);
    }
  }
}
