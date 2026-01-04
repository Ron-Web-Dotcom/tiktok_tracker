import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/community_insights_card_widget.dart';
import './widgets/content_optimization_card_widget.dart';
import './widgets/offline_mode_card_widget.dart';
import './widgets/premium_preview_card_widget.dart';
import './widgets/public_analytics_card_widget.dart';

class AlternativeFeaturesScreen extends StatefulWidget {
  const AlternativeFeaturesScreen({super.key});

  @override
  State<AlternativeFeaturesScreen> createState() =>
      _AlternativeFeaturesScreenState();
}

class _AlternativeFeaturesScreenState extends State<AlternativeFeaturesScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Alternative Features',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFeatures,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              SizedBox(height: 2.h),
              _buildCategoryFilter(),
              SizedBox(height: 2.h),
              _buildSectionHeader('Analytics Alternatives'),
              SizedBox(height: 1.h),
              PublicAnalyticsCardWidget(),
              SizedBox(height: 2.h),
              _buildSectionHeader('Engagement Tools'),
              SizedBox(height: 1.h),
              ContentOptimizationCardWidget(),
              SizedBox(height: 1.h),
              CommunityInsightsCardWidget(),
              SizedBox(height: 2.h),
              _buildSectionHeader('System Features'),
              SizedBox(height: 1.h),
              OfflineModeCardWidget(),
              SizedBox(height: 2.h),
              _buildSectionHeader('Premium Upgrade'),
              SizedBox(height: 1.h),
              PremiumPreviewCardWidget(),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.white, size: 32),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enhanced Features',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Workarounds and alternatives within TikTok API compliance',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Analytics', 'Engagement', 'System', 'Premium'];

    return SizedBox(
      height: 5.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              backgroundColor: AppTheme.surfaceLight,
              selectedColor: AppTheme.primaryLight,
              labelStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimaryLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryLight
                      : AppTheme.dividerLight,
                ),
              ),
            ),
          );
        },
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

  Future<void> _refreshFeatures() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Features updated'),
          backgroundColor: AppTheme.successLight,
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Alternative Features',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'These features provide enhanced functionality within TikTok API limitations. They use publicly available data and compliant methods to deliver insights.',
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