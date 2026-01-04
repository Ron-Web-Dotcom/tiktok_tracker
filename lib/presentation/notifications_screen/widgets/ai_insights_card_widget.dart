import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/openai_service.dart';

/// AI Insights Card Widget - Displays OpenAI analysis results
/// Shows unfollowed users, detected patterns, and recommendations
class AIInsightsCardWidget extends StatelessWidget {
  final FollowerAnalysisResult analysisResult;
  final VoidCallback onDismiss;

  const AIInsightsCardWidget({
    super.key,
    required this.analysisResult,
    required this.onDismiss,
  });

  Color _getSeverityColor(String severity, ThemeData theme) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return AppTheme.warningLight;
      case 'low':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'auto_awesome',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'AI Analysis Results',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onDismiss();
                },
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Unfollowed Users Section
          if (analysisResult.unfollowedUsers.isNotEmpty)
            ..._buildUnfollowedUsersSection(theme),

          // Patterns Section
          if (analysisResult.patterns.isNotEmpty)
            ..._buildPatternsSection(theme),

          // Recommendations Section
          if (analysisResult.recommendations.isNotEmpty)
            ..._buildRecommendationsSection(theme),
        ],
      ),
    );
  }

  List<Widget> _buildUnfollowedUsersSection(ThemeData theme) {
    return [
      _buildSectionHeader(
        theme,
        'Users Who Unfollowed',
        'person_remove',
        Colors.red,
      ),
      SizedBox(height: 1.h),
      ...analysisResult.unfollowedUsers.map(
        (user) => _buildUnfollowedUserItem(theme, user),
      ),
      SizedBox(height: 2.h),
    ];
  }

  List<Widget> _buildPatternsSection(ThemeData theme) {
    return [
      _buildSectionHeader(
        theme,
        'Detected Patterns',
        'insights',
        AppTheme.warningLight,
      ),
      SizedBox(height: 1.h),
      ...analysisResult.patterns.map(
        (pattern) => _buildPatternItem(theme, pattern),
      ),
      SizedBox(height: 2.h),
    ];
  }

  List<Widget> _buildRecommendationsSection(ThemeData theme) {
    return [
      _buildSectionHeader(
        theme,
        'Recommendations',
        'lightbulb',
        theme.colorScheme.primary,
      ),
      SizedBox(height: 1.h),
      ...analysisResult.recommendations.map(
        (rec) => _buildRecommendationItem(theme, rec),
      ),
    ];
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    String iconName,
    Color color,
  ) {
    return Row(
      children: [
        CustomIconWidget(iconName: iconName, color: color, size: 20),
        SizedBox(width: 2.w),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUnfollowedUserItem(ThemeData theme, Map<String, dynamic> user) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            child: CustomIconWidget(
              iconName: 'person',
              color: Colors.red,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'] ?? 'Unknown',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user['username'] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (user['reason'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.h),
                    child: Text(
                      user['reason'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
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

  Widget _buildPatternItem(ThemeData theme, Map<String, dynamic> pattern) {
    final severity = pattern['severity'] ?? 'medium';
    final color = _getSeverityColor(severity, theme);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomIconWidget(
              iconName: 'trending_up',
              color: color,
              size: 16,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pattern['pattern'] ?? 'Pattern',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  pattern['description'] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    ThemeData theme,
    Map<String, dynamic> recommendation,
  ) {
    final impact = recommendation['impact'] ?? 'medium';
    final color = _getSeverityColor(impact, theme);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: 'check_circle', color: color, size: 20),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['category'] ?? 'Recommendation',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  recommendation['suggestion'] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
