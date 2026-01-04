import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget displaying relationship status and action buttons
class RelationshipStatusWidget extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onFollowToggle;
  final VoidCallback onBlock;
  final VoidCallback onMessage;

  const RelationshipStatusWidget({
    super.key,
    required this.userData,
    required this.onFollowToggle,
    required this.onBlock,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFollowing = userData["isFollowing"] as bool;
    final followsYou = userData["followsYou"] as bool;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        children: [
          // Relationship Status Badge
          if (followsYou)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'person_add_alt_1',
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Follows you',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 2.h),

          // Action Buttons
          Row(
            children: [
              // Follow/Unfollow Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onFollowToggle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? theme.colorScheme.surface
                        : theme.colorScheme.primary,
                    foregroundColor: isFollowing
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onPrimary,
                    side: isFollowing
                        ? BorderSide(color: theme.colorScheme.outline)
                        : null,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: isFollowing ? 'person_remove' : 'person_add',
                        color: isFollowing
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onPrimary,
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        isFollowing ? 'Unfollow' : 'Follow',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 3.w),

              // Message Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onMessage();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  child: CustomIconWidget(
                    iconName: 'message',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
              ),
              SizedBox(width: 3.w),

              // Block Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showBlockDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  child: CustomIconWidget(
                    iconName: 'block',
                    color: theme.colorScheme.error,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block User?', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to block ${userData["username"]}? They won\'t be able to find your profile or see your content.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onBlock();
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}
