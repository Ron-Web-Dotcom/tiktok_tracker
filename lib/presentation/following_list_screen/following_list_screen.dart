import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/tiktok_service.dart';
import '../../services/openai_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/following_card_widget.dart';
import './widgets/not_following_back_section_widget.dart';
import './widgets/smart_suggestions_widget.dart';

/// Following List Screen - Manages accounts the user follows with emphasis on
/// identifying non-reciprocal relationships and engagement patterns
class FollowingListScreen extends StatefulWidget {
  const FollowingListScreen({super.key});

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TikTokService _tiktokService = TikTokService();
  final OpenAIService _openaiService = OpenAIService();

  String _searchQuery = '';
  bool _isSearching = false;
  bool _isRefreshing = false;
  bool _isBulkSelectionMode = false;
  bool _isLoadingData = true;
  final Set<int> _selectedFollowingIds = {};
  String _activeFilter = 'All';
  bool _showScrollToTop = false;

  // Real data from TikTok API (sorted latest first)
  List<Map<String, dynamic>> _followingList = [];
  List<Map<String, dynamic>> _smartSuggestions = [];

  // Undo stack for recent unfollow actions
  final List<Map<String, dynamic>> _undoStack = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _scrollController.addListener(_handleScroll);
    _loadRealData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load real data from TikTok API
  Future<void> _loadRealData() async {
    setState(() => _isLoadingData = true);

    try {
      // Fetch real follower relationships from TikTok
      final relationships = await _tiktokService.fetchFollowerRelationships();
      final following =
          relationships['following'] as List<Map<String, dynamic>>;
      final followers =
          relationships['followers'] as List<Map<String, dynamic>>;

      // Generate smart suggestions using OpenAI
      final openaiClient = OpenAIClient(_openaiService.dio);
      final suggestions = await openaiClient.generateSmartSuggestions(
        followers: followers,
        following: following,
      );

      setState(() {
        // Data is already sorted latest-first from TikTok service
        _followingList = following;
        _smartSuggestions = suggestions;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleScroll() {
    if (_scrollController.offset > 200 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 200 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  List<Map<String, dynamic>> get _filteredFollowingList {
    var filtered = _followingList.where((following) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (following["username"] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (following["displayName"] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesFilter =
          _activeFilter == 'All' ||
          (_activeFilter == 'Not Following Back' &&
              !(following["followsBack"] as bool)) ||
          (_activeFilter == 'High Engagement' &&
              (following["engagementScore"] as int) >= 70) ||
          (_activeFilter == 'Low Engagement' &&
              (following["engagementScore"] as int) < 50) ||
          (_activeFilter == 'Inactive' && !(following["isActive"] as bool));

      return matchesSearch && matchesFilter;
    }).toList();

    // Sort by follow date descending (latest first)
    filtered.sort(
      (a, b) =>
          (b["followDate"] as DateTime).compareTo(a["followDate"] as DateTime),
    );

    return filtered;
  }

  List<Map<String, dynamic>> get _notFollowingBackList {
    final list = _followingList
        .where((following) => !(following["followsBack"] as bool))
        .toList();

    // Sort by follow date descending (latest first)
    list.sort(
      (a, b) =>
          (b["followDate"] as DateTime).compareTo(a["followDate"] as DateTime),
    );

    return list;
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    await _loadRealData();

    setState(() => _isRefreshing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Following list updated'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleUnfollow(Map<String, dynamic> following) {
    HapticFeedback.mediumImpact();

    // Add to undo stack
    _undoStack.add(following);

    setState(() {
      _followingList.removeWhere((f) => f["id"] == following["id"]);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unfollowed ${following["username"]}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => _handleUndo(following),
        ),
      ),
    );
  }

  void _handleUndo(Map<String, dynamic> following) {
    HapticFeedback.lightImpact();

    setState(() {
      _followingList.add(following);
      _undoStack.remove(following);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restored ${following["username"]}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleBulkUnfollow() {
    if (_selectedFollowingIds.isEmpty) return;

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Unfollow'),
        content: Text(
          'Are you sure you want to unfollow ${_selectedFollowingIds.length} accounts? This action can be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkUnfollow();
            },
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
  }

  void _performBulkUnfollow() {
    final unfollowedCount = _selectedFollowingIds.length;

    setState(() {
      _followingList.removeWhere(
        (f) => _selectedFollowingIds.contains(f["id"]),
      );
      _selectedFollowingIds.clear();
      _isBulkSelectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unfollowed $unfollowedCount accounts'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showFilterBottomSheet() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        activeFilter: _activeFilter,
        onFilterSelected: (filter) {
          setState(() => _activeFilter = filter);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleBulkSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      _isBulkSelectionMode = !_isBulkSelectionMode;
      if (!_isBulkSelectionMode) {
        _selectedFollowingIds.clear();
      }
    });
  }

  void _toggleSelection(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFollowingIds.contains(id)
          ? _selectedFollowingIds.remove(id)
          : _selectedFollowingIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar.standard(
        title: 'Following',
        subtitle: '${_followingList.length} accounts',
        actions: [
          if (_isBulkSelectionMode)
            TextButton(
              onPressed: _handleBulkUnfollow,
              child: Text(
                'Unfollow (${_selectedFollowingIds.length})',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          else
            IconButton(
              icon: CustomIconWidget(
                iconName: 'checklist',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _toggleBulkSelection,
              tooltip: 'Bulk Selection',
            ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: _activeFilter != 'All'
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Followers'),
                Tab(text: 'Following'),
              ],
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacementNamed(
                    context,
                    '/followers-list-screen',
                  );
                }
              },
            ),
          ),

          // Search Bar
          Container(
            padding: EdgeInsets.all(4.w),
            color: theme.colorScheme.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search following...',
                prefixIcon: CustomIconWidget(
                  iconName: 'search',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: CustomIconWidget(
                          iconName: 'clear',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.h,
                ),
              ),
            ),
          ),

          // Active Filter Indicator
          if (_activeFilter != 'All')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'filter_alt',
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Filter: $_activeFilter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _activeFilter = 'All'),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Not Following Back Section
                  if (_notFollowingBackList.isNotEmpty &&
                      _activeFilter == 'All')
                    SliverToBoxAdapter(
                      child: NotFollowingBackSectionWidget(
                        notFollowingBackList: _notFollowingBackList,
                        onUnfollow: _handleUnfollow,
                      ),
                    ),

                  // Smart Suggestions (AI-powered)
                  if (_activeFilter == 'All' && !_isLoadingData)
                    SliverToBoxAdapter(
                      child: SmartSuggestionsWidget(
                        suggestions: _smartSuggestions,
                        onRefresh: _loadRealData,
                      ),
                    ),

                  // Following List
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    sliver: _filteredFollowingList.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'person_search',
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 64,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No following accounts'
                                        : 'No results found',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Start following accounts to see them here'
                                        : 'Try adjusting your search or filters',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final following = _filteredFollowingList[index];
                              return FollowingCardWidget(
                                following: following,
                                isSelected: _selectedFollowingIds.contains(
                                  following["id"],
                                ),
                                isBulkSelectionMode: _isBulkSelectionMode,
                                onTap: () {
                                  if (_isBulkSelectionMode) {
                                    _toggleSelection(following["id"] as int);
                                  } else {
                                    Navigator.pushNamed(
                                      context,
                                      '/profile-detail-screen',
                                      arguments: following,
                                    );
                                  }
                                },
                                onUnfollow: () => _handleUnfollow(following),
                              );
                            }, childCount: _filteredFollowingList.length),
                          ),
                  ),

                  // Bottom Padding
                  SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              child: CustomIconWidget(
                iconName: 'arrow_upward',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
            )
          : null,
      bottomNavigationBar: const CustomBottomBar(
        currentRoute: '/following-list-screen',
      ),
    );
  }
}
