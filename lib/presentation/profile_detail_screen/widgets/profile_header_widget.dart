import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Profile header widget displaying user avatar, username, and verification badge
class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileHeaderWidget({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
      child: Column(
        children: [
          // Profile Image with Hero Animation
          Hero(
            tag: 'profile_${userData["id"]}',
            child: Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 3),
              ),
              child: ClipOval(
                child: CustomImageWidget(
                  imageUrl: userData["profileImage"] as String,
                  width: 30.w,
                  height: 30.w,
                  fit: BoxFit.cover,
                  semanticLabel: userData["semanticLabel"] as String,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Username with Verification Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  userData["username"] as String,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (userData["isVerified"] == true) ...[
                SizedBox(width: 1.w),
                CustomIconWidget(
                  iconName: 'verified',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ],
          ),
          SizedBox(height: 0.5.h),

          // Display Name
          Text(
            userData["displayName"] as String,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),

          // Follower Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(
                context,
                'Followers',
                userData["followersCount"] as int,
              ),
              Container(
                width: 1,
                height: 5.h,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              _buildStatColumn(
                context,
                'Following',
                userData["followingCount"] as int,
              ),
              Container(
                width: 1,
                height: 5.h,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              _buildStatColumn(context, 'Likes', userData["likesCount"] as int),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, int count) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          _formatCount(count),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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
