import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Section widget highlighting accounts that don't follow back
class NotFollowingBackSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> notFollowingBackList;
  final Function(Map<String, dynamic>) onUnfollow;

  const NotFollowingBackSectionWidget({
    super.key,
    required this.notFollowingBackList,
    required this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (notFollowingBackList.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'person_remove',
                  color: theme.colorScheme.error,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not Following Back',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    Text(
                      '${notFollowingBackList.length} accounts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'These accounts don\'t follow you back. Consider unfollowing to optimize your following list.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: notFollowingBackList.length > 5
                  ? 5
                  : notFollowingBackList.length,
              itemBuilder: (context, index) {
                final user = notFollowingBackList[index];
                return _buildUserCard(context, user);
              },
            ),
          ),
          if (notFollowingBackList.length > 5) ...[
            SizedBox(height: 2.h),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Navigate to filtered view
              },
              child: Text(
                'View All ${notFollowingBackList.length} Accounts',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);

    return Container(
      width: 80,
      margin: EdgeInsets.only(right: 2.w),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: user["avatar"] as String,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    semanticLabel: user["semanticLabel"] as String,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _showQuickUnfollowDialog(context, user);
                  },
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onError,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            user["username"] as String,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQuickUnfollowDialog(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Unfollow'),
        content: Text('Unfollow ${user["username"]}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUnfollow(user);
            },
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
  }
}
