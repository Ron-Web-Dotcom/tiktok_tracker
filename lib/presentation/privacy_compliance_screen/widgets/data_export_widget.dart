import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/tiktok_service.dart';

class DataExportWidget extends StatefulWidget {
  final TikTokService tiktokService;

  const DataExportWidget({super.key, required this.tiktokService});

  @override
  State<DataExportWidget> createState() => _DataExportWidgetState();
}

class _DataExportWidgetState extends State<DataExportWidget> {
  bool _isExporting = false;

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
              Icon(Icons.download, color: AppTheme.primaryLight, size: 24),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Export Your Data',
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
            'Download a complete copy of your data in JSON format. Includes all follower metrics, analytics, and activity history.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
              height: 1.4,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isExporting ? null : _exportData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isExporting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Request Data Export',
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

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      // Fetch real user data from TikTok service
      final exportData = await widget.tiktokService.exportUserData();

      // Convert to formatted JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      setState(() => _isExporting = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Data Export Ready',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data has been successfully exported:',
                  style: GoogleFonts.inter(fontSize: 13.sp),
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataStat(
                        'Followers',
                        exportData['statistics']['totalFollowers'].toString(),
                      ),
                      _buildDataStat(
                        'Following',
                        exportData['statistics']['totalFollowing'].toString(),
                      ),
                      _buildDataStat(
                        'Notifications',
                        exportData['statistics']['totalNotifications']
                            .toString(),
                      ),
                      _buildDataStat(
                        'Export Date',
                        DateTime.parse(
                          exportData['exportDate'],
                        ).toString().split('.')[0],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Data size: ${(jsonString.length / 1024).toStringAsFixed(2)} KB',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showExportSuccess();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                ),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Export Failed',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppTheme.errorLight,
              ),
            ),
            content: Text(
              'Failed to export data: ${e.toString()}',
              style: GoogleFonts.inter(fontSize: 13.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildDataStat(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data export completed successfully'),
        backgroundColor: AppTheme.successLight,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
