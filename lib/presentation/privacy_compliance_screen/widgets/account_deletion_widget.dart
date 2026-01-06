import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/tiktok_service.dart';

class AccountDeletionWidget extends StatefulWidget {
  final TikTokService tiktokService;

  const AccountDeletionWidget({super.key, required this.tiktokService});

  @override
  State<AccountDeletionWidget> createState() => _AccountDeletionWidgetState();
}

class _AccountDeletionWidgetState extends State<AccountDeletionWidget> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.errorLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delete_forever, color: AppTheme.errorLight, size: 24),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Permanently delete your account and all associated data. This action cannot be undone after the 7-day recovery period.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isDeleting
                  ? null
                  : () => _showDeletionDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorLight,
                side: BorderSide(color: AppTheme.errorLight),
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isDeleting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.errorLight,
                      ),
                    )
                  : Text(
                      'Delete My Account',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.errorLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            _buildImpactItem('All follower and following data'),
            _buildImpactItem('Analytics and insights history'),
            _buildImpactItem('Notification preferences'),
            _buildImpactItem('Account settings'),
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.warningLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningLight,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      '7-day recovery period available',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.warningLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeletion(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorLight,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.3.h),
      child: Row(
        children: [
          Icon(Icons.close, size: 16, color: AppTheme.errorLight),
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

  Future<void> _confirmDeletion(BuildContext context) async {
    setState(() => _isDeleting = true);

    try {
      // Call real TikTok service to delete account
      final success = await widget.tiktokService.deleteUserAccount();

      setState(() => _isDeleting = false);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account deletion scheduled. 7-day recovery period active.',
            ),
            backgroundColor: AppTheme.warningLight,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate back to login screen after short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _isDeleting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: AppTheme.errorLight,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
