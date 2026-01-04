import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DataExportWidget extends StatefulWidget {
  const DataExportWidget({super.key});

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

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isExporting = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Export Requested',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Your data export has been requested. You will receive a secure download link via email within 24 hours.',
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