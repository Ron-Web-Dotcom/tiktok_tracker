import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_app_bar.dart';

/// Privacy Policy Screen
/// Displays comprehensive privacy policy and data handling practices
/// Required for App Store and Google Play Store compliance
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(title: 'Privacy Policy', showBackButton: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated Date
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.update, color: Colors.blue.shade700, size: 20.sp),
                  SizedBox(width: 2.w),
                  Text(
                    'Last Updated: January 14, 2026',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Introduction
            _buildSection(
              title: '1. Introduction',
              content:
                  'TikTok Tracker ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),

            // Information We Collect
            _buildSection(
              title: '2. Information We Collect',
              content:
                  'We collect information that you provide directly to us, including:\n\n'
                  '• TikTok Account Information: Username, profile picture, follower count, following count\n'
                  '• Usage Data: App interactions, feature usage, sync timestamps\n'
                  '• Device Information: Device type, operating system, unique device identifiers\n'
                  '• Analytics Data: App performance metrics, crash reports (if enabled)',
            ),

            // How We Use Your Information
            _buildSection(
              title: '3. How We Use Your Information',
              content:
                  'We use the collected information to:\n\n'
                  '• Provide and maintain the app functionality\n'
                  '• Analyze follower patterns and generate insights\n'
                  '• Improve app performance and user experience\n'
                  '• Send notifications about follower changes\n'
                  '• Comply with legal obligations',
            ),

            // Data Storage and Security
            _buildSection(
              title: '4. Data Storage and Security',
              content:
                  'Your data is stored locally on your device using encrypted storage. We implement industry-standard security measures to protect your information. However, no method of transmission over the internet is 100% secure.',
            ),

            // Third-Party Services
            _buildSection(
              title: '5. Third-Party Services',
              content:
                  'We use the following third-party services:\n\n'
                  '• TikTok API: To fetch your follower data (requires your authorization)\n'
                  '• OpenAI API: To generate AI-powered insights (data is anonymized)\n'
                  '• Analytics Services: To improve app performance (optional, can be disabled)',
            ),

            // Your Rights
            _buildSection(
              title: '6. Your Rights',
              content:
                  'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Request data deletion\n'
                  '• Export your data\n'
                  '• Opt-out of analytics\n'
                  '• Revoke TikTok API access at any time',
            ),

            // Data Retention
            _buildSection(
              title: '7. Data Retention',
              content:
                  'We retain your data only as long as necessary to provide our services. You can delete your data at any time through the Privacy & Compliance screen in the app.',
            ),

            // Children\'s Privacy
            _buildSection(
              title: '8. Children\'s Privacy',
              content:
                  'Our app is not intended for users under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
            ),

            // Changes to This Policy
            _buildSection(
              title: '9. Changes to This Privacy Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
            ),

            // Contact Us
            _buildSection(
              title: '10. Contact Us',
              content:
                  'If you have questions about this Privacy Policy, please contact us at:\n\n'
                  'Email: privacy@tiktoktracker.app\n'
                  'Website: https://tiktoktracker.app/privacy',
            ),

            SizedBox(height: 3.h),

            // Action Buttons
            _buildActionButton(
              context,
              icon: Icons.email_outlined,
              label: 'Contact Privacy Team',
              onTap: () => _launchEmail('privacy@tiktoktracker.app'),
            ),
            SizedBox(height: 2.h),
            _buildActionButton(
              context,
              icon: Icons.language,
              label: 'View Full Policy Online',
              onTap: () => _launchUrl('https://tiktoktracker.app/privacy'),
            ),
            SizedBox(height: 2.h),
            _buildActionButton(
              context,
              icon: Icons.settings,
              label: 'Privacy Settings',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.privacyCompliance),
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: Colors.blue.shade700, size: 20.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Privacy Policy Inquiry',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
