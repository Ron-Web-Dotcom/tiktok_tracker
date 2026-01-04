import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Filter chip widget for displaying active filters
///
/// Features:
/// - Chip with label and remove button
/// - Smooth animations
/// - Theme-aware styling
class FilterChipWidget extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(right: 2.w),
      child: Chip(
        label: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        deleteIcon: CustomIconWidget(
          iconName: Icons.close.codePoint.toString(),
          size: 16,
          color: theme.colorScheme.primary,
        ),
        onDeleted: onRemove,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
