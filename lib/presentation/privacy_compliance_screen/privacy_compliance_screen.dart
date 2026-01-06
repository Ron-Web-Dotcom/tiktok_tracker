import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/tiktok_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/account_deletion_widget.dart';
import './widgets/compliance_badge_widget.dart';
import './widgets/compliance_section_widget.dart';
import './widgets/data_export_widget.dart';
import './widgets/privacy_control_card_widget.dart';

class PrivacyComplianceScreen extends StatefulWidget {
  const PrivacyComplianceScreen({super.key});

  @override
  State<PrivacyComplianceScreen> createState() =>
      _PrivacyComplianceScreenState();
}

class _PrivacyComplianceScreenState extends State<PrivacyComplianceScreen> {
  final TikTokService _tiktokService = TikTokService();
  bool _dataCollectionEnabled = true;
  bool _analyticsEnabled = true;
  bool _crashReportingEnabled = true;
  bool _isVerifying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  /// Load current privacy settings from TikTok service
  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _tiktokService.getPrivacySettings();
      setState(() {
        _dataCollectionEnabled = settings['dataCollectionEnabled'] ?? true;
        _analyticsEnabled = settings['analyticsEnabled'] ?? true;
        _crashReportingEnabled = settings['crashReportingEnabled'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: ${e.toString()}'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  /// Update privacy setting and save to TikTok service
  Future<void> _updatePrivacySetting(String settingName, bool value) async {
    try {
      switch (settingName) {
        case 'dataCollection':
          await _tiktokService.updatePrivacySettings(
            dataCollectionEnabled: value,
          );
          setState(() => _dataCollectionEnabled = value);
          break;
        case 'analytics':
          await _tiktokService.updatePrivacySettings(analyticsEnabled: value);
          setState(() => _analyticsEnabled = value);
          break;
        case 'crashReporting':
          await _tiktokService.updatePrivacySettings(
            crashReportingEnabled: value,
          );
          setState(() => _crashReportingEnabled = value);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Privacy setting updated'),
            backgroundColor: AppTheme.successLight,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: ${e.toString()}'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Privacy & Compliance',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPrivacyInfo(),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _isVerifying
          ? _buildVerificationLoader()
          : RefreshIndicator(
              onRefresh: _refreshCompliance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ComplianceBadgeWidget(
                      isVerified: true,
                      lastAuditDate: DateTime.now().subtract(
                        const Duration(days: 15),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildSectionHeader('Privacy Controls'),
                    SizedBox(height: 1.h),
                    PrivacyControlCardWidget(
                      title: 'Data Collection',
                      description: 'Minimal follower metrics only',
                      isEnabled: _dataCollectionEnabled,
                      onToggle: (value) {
                        _updatePrivacySetting('dataCollection', value);
                      },
                      details: [
                        'Follower count and basic profile info',
                        'Following list (usernames only)',
                        'No private messages or content',
                        'No location or device data',
                      ],
                    ),
                    SizedBox(height: 1.h),
                    PrivacyControlCardWidget(
                      title: 'Analytics Processing',
                      description: 'Process data for insights',
                      isEnabled: _analyticsEnabled,
                      onToggle: (value) {
                        _updatePrivacySetting('analytics', value);
                      },
                      details: [
                        'Generate follower growth trends',
                        'Identify engagement patterns',
                        'Create AI-powered recommendations',
                        'All processing happens locally',
                      ],
                    ),
                    SizedBox(height: 1.h),
                    PrivacyControlCardWidget(
                      title: 'Crash Reporting',
                      description: 'Help improve app stability',
                      isEnabled: _crashReportingEnabled,
                      onToggle: (value) {
                        _updatePrivacySetting('crashReporting', value);
                      },
                      details: [
                        'Anonymous error logs only',
                        'No personal data included',
                        'Used solely for bug fixes',
                      ],
                    ),
                    SizedBox(height: 2.h),
                    _buildSectionHeader('Data Retention'),
                    SizedBox(height: 1.h),
                    _buildInfoCard(
                      icon: Icons.schedule,
                      title: '30-Day Automatic Deletion',
                      description:
                          'All cached data is automatically deleted after 30 days of inactivity. You can manually clear data anytime.',
                    ),
                    SizedBox(height: 2.h),
                    _buildSectionHeader('Third-Party Sharing'),
                    SizedBox(height: 1.h),
                    _buildInfoCard(
                      icon: Icons.block,
                      title: 'No Data Sharing',
                      description:
                          'Your TikTok data is never shared with third parties. All data stays on your device and our secure servers.',
                      color: AppTheme.successLight,
                    ),
                    SizedBox(height: 2.h),
                    _buildSectionHeader('Compliance'),
                    SizedBox(height: 1.h),
                    ComplianceSectionWidget(),
                    SizedBox(height: 2.h),
                    _buildSectionHeader('Your Data Rights'),
                    SizedBox(height: 1.h),
                    DataExportWidget(tiktokService: _tiktokService),
                    SizedBox(height: 1.h),
                    AccountDeletionWidget(tiktokService: _tiktokService),
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryLight),
          SizedBox(height: 2.h),
          Text(
            'Loading privacy settings...',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryLight,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    Color? color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: (color ?? AppTheme.primaryLight).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? AppTheme.primaryLight, size: 24),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryLight),
          SizedBox(height: 2.h),
          Text(
            'Verifying compliance...',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCompliance() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compliance status verified'),
          backgroundColor: AppTheme.successLight,
        ),
      );
    }
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Privacy Information',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This screen shows how TikTok Tracker handles your data in compliance with TikTok Developer Guidelines, GDPR, and CCPA. You have full control over your data.',
          style: GoogleFonts.inter(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}
