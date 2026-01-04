import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty state widget for when no followers are found
///
/// Features:
/// - Illustration
/// - Helpful message
/// - Call-to-action button
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onInviteFriends;

  const EmptyStateWidget({super.key, required this.onInviteFriends});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: Icons.people_outline.codePoint.toString(),
              size: 30.w,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            SizedBox(height: 3.h),
            Text(
              'No Followers Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your filters or search query to find followers',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: onInviteFriends,
              icon: CustomIconWidget(
                iconName: Icons.person_add.codePoint.toString(),
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: const Text('Invite Friends'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
