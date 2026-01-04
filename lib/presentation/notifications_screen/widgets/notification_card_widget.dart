import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Notification card widget with swipe actions and platform-specific styling
///
/// Features:
/// - Swipe right to mark as read
/// - Swipe left to delete with undo
/// - Tap to expand for details
/// - Visual indicators for notification types
/// - Batch selection support
class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isSelected;
  final bool batchSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    required this.isSelected,
    required this.batchSelectionMode,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_follower':
        return Icons.person_add;
      case 'unfollow':
        return Icons.person_remove;
      case 'mutual_connection':
        return Icons.people;
      case 'milestone':
        return Icons.emoji_events;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(ThemeData theme, String type) {
    switch (type) {
      case 'new_follower':
        return theme.colorScheme.primary;
      case 'unfollow':
        return theme.colorScheme.error;
      case 'mutual_connection':
        return theme.colorScheme.tertiary;
      case 'milestone':
        return const Color(0xFFFFD700); // Gold
      case 'system':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification["isRead"] as bool;
    final type = notification["type"] as String;
    final timestamp = notification["timestamp"] as DateTime;

    Widget cardContent = Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : isRead
              ? Colors.transparent
              : theme.colorScheme.primary.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (batchSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: 2.w),
                ],
                _buildAvatar(theme, type),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification["title"] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _formatTimestamp(timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        notification["message"] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isRead
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isRead && !batchSelectionMode) ...[
                  SizedBox(width: 2.w),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with Slidable for swipe actions (only when not in batch selection mode)
    if (!batchSelectionMode) {
      return Slidable(
        key: ValueKey(notification["id"]),
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                onMarkAsRead();
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              icon: Icons.mark_email_read,
              label: 'Read',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                onDelete();
              },
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildAvatar(ThemeData theme, String type) {
    final avatar = notification["avatar"] as String?;
    final semanticLabel = notification["semanticLabel"] as String?;
    final iconColor = _getNotificationColor(theme, type);

    if (avatar != null && semanticLabel != null) {
      return Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 2),
        ),
        child: ClipOval(
          child: CustomImageWidget(
            imageUrl: avatar,
            width: 12.w,
            height: 12.w,
            fit: BoxFit.cover,
            semanticLabel: semanticLabel,
          ),
        ),
      );
    }

    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: _getNotificationIcon(type).codePoint.toRadixString(16),
          color: iconColor,
          size: 6.w,
        ),
      ),
    );
  }
}
