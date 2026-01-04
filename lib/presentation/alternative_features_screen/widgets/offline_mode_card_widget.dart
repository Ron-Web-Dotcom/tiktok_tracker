import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OfflineModeCardWidget extends StatelessWidget {
  const OfflineModeCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.warningLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.cloud_off,
                  color: AppTheme.warningLight,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline Mode',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    _buildStatusBadge(
                      'Always Available',
                      AppTheme.successLight,
                    ),
                  ],
                ),
              ),
              _buildSyncIndicator(true),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Access cached data during API downtime or network issues. Data syncs automatically when connection is restored.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
              height: 1.4,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildFeatureItem('View cached follower lists'),
          _buildFeatureItem('Access historical analytics'),
          _buildFeatureItem('Review past notifications'),
          _buildFeatureItem('Auto-sync when online'),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.successLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppTheme.successLight,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Last synced: 2 hours ago',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.successLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSyncIndicator(bool isSynced) {
    return Container(
      padding: EdgeInsets.all(1.5.w),
      decoration: BoxDecoration(
        color: isSynced
            ? AppTheme.successLight.withValues(alpha: 0.1)
            : AppTheme.warningLight.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSynced ? Icons.cloud_done : Icons.sync,
        size: 16,
        color: isSynced ? AppTheme.successLight : AppTheme.warningLight,
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: AppTheme.successLight),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
