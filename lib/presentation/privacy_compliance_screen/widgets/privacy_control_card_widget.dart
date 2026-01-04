import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PrivacyControlCardWidget extends StatelessWidget {
  final String title;
  final String description;
  final bool isEnabled;
  final Function(bool) onToggle;
  final List<String> details;

  const PrivacyControlCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.onToggle,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          childrenPadding: EdgeInsets.only(left: 3.w, right: 3.w, bottom: 2.h),
          leading: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppTheme.primaryLight.withValues(alpha: 0.1)
                  : AppTheme.textDisabledLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              isEnabled ? Icons.check_circle : Icons.cancel,
              color: isEnabled
                  ? AppTheme.primaryLight
                  : AppTheme.textDisabledLight,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 0.5.h),
            child: Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          trailing: Switch(
            value: isEnabled,
            onChanged: onToggle,
            activeThumbColor: AppTheme.primaryLight,
          ),
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.map((detail) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.5.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check,
                          size: 16,
                          color: AppTheme.successLight,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            detail,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
