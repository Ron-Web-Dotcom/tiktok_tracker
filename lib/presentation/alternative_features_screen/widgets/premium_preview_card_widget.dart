import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PremiumPreviewCardWidget extends StatelessWidget {
  const PremiumPreviewCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentLight,
            AppTheme.accentLight.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Icon(
              Icons.star,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Premium Features',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Unlock advanced analytics and unlimited API calls',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 2.h),
                _buildPremiumFeature('Unlimited API requests'),
                _buildPremiumFeature('Advanced trend predictions'),
                _buildPremiumFeature('Real-time notifications'),
                _buildPremiumFeature('Export detailed reports'),
                _buildPremiumFeature('Priority support'),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$9.99/month',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '7-day free trial',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showUpgradeDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.accentLight,
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.5.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Upgrade',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.white),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upgrade to Premium',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start your 7-day free trial and unlock:',
              style: GoogleFonts.inter(fontSize: 13.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              '• Unlimited API access\n• Advanced analytics\n• Real-time updates\n• Priority support',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
                height: 1.6,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              'Cancel anytime during trial period.',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Premium upgrade coming soon!'),
                  backgroundColor: AppTheme.successLight,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
              foregroundColor: Colors.white,
            ),
            child: Text('Start Trial'),
          ),
        ],
      ),
    );
  }
}
