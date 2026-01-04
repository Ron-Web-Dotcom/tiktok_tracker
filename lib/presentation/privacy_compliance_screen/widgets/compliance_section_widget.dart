import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ComplianceSectionWidget extends StatelessWidget {
  const ComplianceSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final compliances = [
      {
        'title': 'TikTok Community Guidelines',
        'status': 'Compliant',
        'icon': Icons.people,
      },
      {
        'title': 'TikTok Developer Policy',
        'status': 'Verified',
        'icon': Icons.code,
      },
      {
        'title': 'GDPR (EU Privacy Law)',
        'status': 'Compliant',
        'icon': Icons.security,
      },
      {
        'title': 'CCPA (California Privacy)',
        'status': 'Compliant',
        'icon': Icons.gavel,
      },
    ];

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
      child: Column(
        children: compliances.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == compliances.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
                leading: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.successLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: AppTheme.successLight,
                    size: 20,
                  ),
                ),
                title: Text(
                  item['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    item['status'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successLight,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 3.w,
                  endIndent: 3.w,
                  color: AppTheme.dividerLight,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
