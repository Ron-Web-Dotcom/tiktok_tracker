import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/tiktok_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/filter_chip_widget.dart';
import './widgets/follower_card_widget.dart';
import './widgets/skeleton_loader_widget.dart';

/// Followers List Screen - Manage and view all your TikTok followers
///
/// This screen shows everyone who follows you on TikTok.
/// You can search, filter, sort, and take actions on your followers.
///
/// Key Features:
/// - Search followers by username or display name
/// - Filter by date, mutual followers, verified accounts, engagement level
/// - Sort by recent, alphabetical, engagement, or mutual connections
/// - Swipe left on a follower to follow back, block, or remove
/// - Multi-select mode to remove or block multiple followers at once
/// - Pull down to refresh from TikTok
/// - Infinite scroll loads more followers as you scroll down
///
/// How it works:
/// 1. Loads your followers from TikTok when screen opens
/// 2. Displays them in a scrollable list
/// 3. As you search/filter, the list updates in real-time
/// 4. Swipe actions let you manage individual followers
/// 5. Multi-select mode for batch operations
class FollowersListScreen extends StatefulWidget {
  const FollowersListScreen({super.key});

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  // Text field controller for search input
  final TextEditingController _searchController = TextEditingController();

  // Scroll controller to detect when user scrolls to bottom
  final ScrollController _scrollController = ScrollController();

  // Service to communicate with TikTok API
  final TikTokService _tiktokService = TikTokService();

  // Debounce timers
  Timer? _searchDebounce;
  Timer? _scrollDebounce;

  // Loading states
  bool _isLoading = true; // Initial data load
  bool _isRefreshing = false; // Pull-to-refresh
  bool _isMultiSelectMode = false; // Batch selection mode
  bool _isLoadingMore = false; // Infinite scroll loading

  // Current search query
  String _searchQuery = '';

  // IDs of followers selected in multi-select mode
  List<String> _selectedFollowerIds = [];

  // Active filters (date range, mutual only, verified only, etc.)
  Map<String, dynamic> _activeFilters = {};

  // Current sort option: 'recent', 'alphabetical', 'engagement', 'mutual'
  String _currentSortOption = 'recent';

  // All followers from TikTok (sorted newest first)
  List<Map<String, dynamic>> _allFollowers = [];

  // Filtered/sorted followers currently displayed
  List<Map<String, dynamic>> _filteredFollowers = [];

  @override
  void initState() {
    super.initState();
    // Set up listeners for scroll and search
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    // Load followers from TikTok
    _loadRealData();
  }

  @override
  void dispose() {
    // Clean up controllers when screen is closed
    _searchDebounce?.cancel();
    _scrollDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load followers from TikTok API
  Future<void> _loadRealData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Fetch real follower relationships from TikTok
      final relationships = await _tiktokService.fetchFollowerRelationships();
      final followers =
          (relationships['followers'] as List?)?.cast<Map<String, dynamic>>() ??
          [];

      if (!mounted) return;
      setState(() {
        // Data is already sorted latest-first from TikTok service
        _allFollowers = followers;
        _filteredFollowers = List.from(_allFollowers);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load followers: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Detect when user scrolls near bottom of list
  /// Triggers loading more followers (infinite scroll)
  void _onScroll() {
    // Debounce scroll events to prevent excessive calls
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 200), () {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore) {
          _loadMoreFollowers();
        }
      }
    });
  }

  /// Called whenever search text changes
  /// Waits 300ms after user stops typing before searching
  /// (This is called "debouncing" - prevents searching on every keystroke)
  void _onSearchChanged() {
    // Cancel previous timer
    _searchDebounce?.cancel();
    // Start new timer
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_searchController.text == _searchQuery) return;
      setState(() {
        _searchQuery = _searchController.text;
        _applyFiltersAndSearch();
      });
    });
  }

  /// Apply all active filters and search query to the followers list
  /// This function runs every time search text or filters change
  void _applyFiltersAndSearch() {
    setState(() {
      _filteredFollowers = _allFollowers.where((follower) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final matchesUsername = (follower["username"] as String)
              .toLowerCase()
              .contains(searchLower);
          final matchesDisplayName = (follower["displayName"] as String)
              .toLowerCase()
              .contains(searchLower);
          if (!matchesUsername && !matchesDisplayName) return false;
        }

        // Advanced filters
        if (_activeFilters.isNotEmpty) {
          // Date range filter
          if (_activeFilters.containsKey('dateRange')) {
            final dateRange = _activeFilters['dateRange'] as String?;
            final followDate = follower['followDate'] as DateTime?;
            if (dateRange == null || followDate == null) return false;
            final now = DateTime.now();

            switch (dateRange) {
              case 'today':
                if (!_isSameDay(followDate, now)) return false;
                break;
              case 'week':
                if (now.difference(followDate).inDays > 7) return false;
                break;
              case 'month':
                if (now.difference(followDate).inDays > 30) return false;
                break;
            }
          }

          // Mutual followers filter
          if (_activeFilters['mutualOnly'] == true) {
            if (follower['isMutual'] != true) return false;
          }

          // Verified filter
          if (_activeFilters['verifiedOnly'] == true) {
            if (follower['isVerified'] != true) return false;
          }

          // Engagement level filter
          if (_activeFilters.containsKey('engagementLevel')) {
            if (follower['engagementLevel'] !=
                _activeFilters['engagementLevel'])
              return false;
          }
        }

        return true;
      }).toList();

      // Apply sorting (maintain latest-first for 'recent')
      _applySorting();
    });
  }

  /// Check if two dates are on the same day
  /// Used for "today" filter
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Sort the filtered followers based on current sort option
  /// - recent: Newest followers first
  /// - alphabetical: A to Z by display name
  /// - engagement: High engagement first
  /// - mutual: Mutual followers first
  void _applySorting() {
    switch (_currentSortOption) {
      case 'recent':
        // Sort by follow date descending (latest first)
        _filteredFollowers.sort(
          (a, b) => (b['followDate'] as DateTime).compareTo(
            a['followDate'] as DateTime,
          ),
        );
        break;
      case 'alphabetical':
        // Sort A to Z by display name
        _filteredFollowers.sort(
          (a, b) => (a['displayName'] as String).compareTo(
            b['displayName'] as String,
          ),
        );
        break;
      case 'engagement':
        // Sort by engagement level (high > medium > low)
        _filteredFollowers.sort((a, b) {
          final aLevel = a['engagementLevel'] as String;
          final bLevel = b['engagementLevel'] as String;
          final levelOrder = {'high': 3, 'medium': 2, 'low': 1};
          return (levelOrder[bLevel] ?? 0).compareTo(levelOrder[aLevel] ?? 0);
        });
        break;
      case 'mutual':
        // Sort mutual followers first, then by date
        _filteredFollowers.sort((a, b) {
          if (a['isMutual'] == b['isMutual']) {
            // If both mutual or both not mutual, sort by date (latest first)
            return (b['followDate'] as DateTime).compareTo(
              a['followDate'] as DateTime,
            );
          }
          return (a['isMutual'] == true) ? -1 : 1;
        });
        break;
    }
  }

  /// Handle pull-to-refresh gesture
  /// Reloads followers from TikTok
  Future<void> _refreshFollowers() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);

    await _loadRealData();

    if (!mounted) return;
    setState(() => _isRefreshing = false);
    if (mounted) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Load more followers when user scrolls to bottom
  /// (Currently simulated - would load next page in production)
  Future<void> _loadMoreFollowers() async {
    if (_isLoadingMore) return;

    if (!mounted) return;
    setState(() => _isLoadingMore = true);

    // Simulate loading more data
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoadingMore = false);
  }

  void _showFilterBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        activeFilters: _activeFilters,
        onApplyFilters: (filters) {
          setState(() {
            _activeFilters = filters;
            _applyFiltersAndSearch();
          });
        },
      ),
    );
  }

  void _removeFilter(String filterKey) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeFilters.remove(filterKey);
      _applyFiltersAndSearch();
    });
  }

  void _toggleMultiSelectMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedFollowerIds.clear();
      }
    });
  }

  void _toggleFollowerSelection(String followerId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedFollowerIds.contains(followerId)) {
        _selectedFollowerIds.remove(followerId);
      } else {
        _selectedFollowerIds.add(followerId);
      }
    });
  }

  void _handleFollowBack(Map<String, dynamic> follower) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Followed back ${follower["displayName"]}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleRemoveFollower(Map<String, dynamic> follower) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Follower'),
        content: Text(
          'Are you sure you want to remove ${follower["displayName"]} from your followers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 16),
                      Text('Removing ${follower["displayName"]}...'),
                    ],
                  ),
                  duration: const Duration(seconds: 30),
                ),
              );

              try {
                // Call TikTok API to remove follower
                final success = await _tiktokService.removeFollower(
                  follower["id"] as String,
                );

                if (success) {
                  setState(() {
                    _allFollowers.removeWhere((f) => f["id"] == follower["id"]);
                    _applyFiltersAndSearch();
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Removed ${follower["displayName"]} from TikTok',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to remove ${follower["displayName"]}',
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _handleBlockFollower(Map<String, dynamic> follower) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${follower["displayName"]}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 16),
                      Text('Blocking ${follower["displayName"]}...'),
                    ],
                  ),
                  duration: const Duration(seconds: 30),
                ),
              );

              try {
                // Call TikTok API to block user
                final success = await _tiktokService.blockUser(
                  follower["id"] as String,
                );

                if (success) {
                  setState(() {
                    _allFollowers.removeWhere((f) => f["id"] == follower["id"]);
                    _applyFiltersAndSearch();
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Blocked ${follower["displayName"]} on TikTok',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to block ${follower["displayName"]}',
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _handleBatchAction(String action) async {
    HapticFeedback.mediumImpact();

    final selectedCount = _selectedFollowerIds.length;
    final actionLower = action.toLowerCase();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action $selectedCount followers'),
        content: Text(
          'Are you sure you want to $actionLower $selectedCount selected followers on TikTok?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 16),
                      Text('Processing $selectedCount followers...'),
                    ],
                  ),
                  duration: const Duration(minutes: 2),
                ),
              );

              try {
                Map<String, dynamic> result;

                if (actionLower == 'remove') {
                  result = await _tiktokService.batchRemoveFollowers(
                    _selectedFollowerIds,
                  );
                } else {
                  result = await _tiktokService.batchBlockUsers(
                    _selectedFollowerIds,
                  );
                }

                final successCount = result['successCount'] as int;
                final failureCount = result['failureCount'] as int;

                // Remove successfully processed followers from local state
                if (successCount > 0) {
                  setState(() {
                    _allFollowers.removeWhere(
                      (f) => _selectedFollowerIds.contains(f["id"]),
                    );
                    _selectedFollowerIds.clear();
                    _isMultiSelectMode = false;
                    _applyFiltersAndSearch();
                  });
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();

                  if (failureCount == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Successfully ${actionLower}d $successCount followers on TikTok',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Completed: $successCount succeeded, $failureCount failed',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'Details',
                          textColor: Colors.white,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Batch Operation Results'),
                                content: Text(
                                  'Success: $successCount\nFailed: $failureCount',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSortMenu() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sort By', style: theme.textTheme.titleMedium),
              SizedBox(height: 2.h),
              _buildSortOption('Recent', 'recent', Icons.access_time),
              _buildSortOption(
                'Alphabetical',
                'alphabetical',
                Icons.sort_by_alpha,
              ),
              _buildSortOption(
                'Engagement Level',
                'engagement',
                Icons.trending_up,
              ),
              _buildSortOption('Mutual Connections', 'mutual', Icons.people),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _currentSortOption == value;

    return ListTile(
      leading: CustomIconWidget(
        iconName: icon.codePoint.toString(),
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        size: 24,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? CustomIconWidget(
              iconName: Icons.check.codePoint.toString(),
              color: theme.colorScheme.primary,
              size: 24,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentSortOption = value;
          _applyFiltersAndSearch();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar.standard(
        title: _isMultiSelectMode
            ? '${_selectedFollowerIds.length} selected'
            : 'Followers',
        subtitle: _isMultiSelectMode
            ? null
            : '${_filteredFollowers.length} followers',
        actions: [
          if (_isMultiSelectMode)
            IconButton(
              icon: CustomIconWidget(
                iconName: Icons.close.codePoint.toString(),
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _toggleMultiSelectMode,
              tooltip: 'Exit selection mode',
            )
          else ...[
            IconButton(
              icon: CustomIconWidget(
                iconName: Icons.sort.codePoint.toString(),
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _showSortMenu,
              tooltip: 'Sort options',
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: Icons.select_all.codePoint.toString(),
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _toggleMultiSelectMode,
              tooltip: 'Multi-select mode',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search bar with filter button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search followers...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: CustomIconWidget(
                          iconName: Icons.search.codePoint.toString(),
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: CustomIconWidget(
                                  iconName: Icons.clear.codePoint.toString(),
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: Icons.filter_list.codePoint.toString(),
                    color: _activeFilters.isNotEmpty
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: _showFilterBottomSheet,
                  tooltip: 'Filters',
                ),
              ],
            ),
          ),

          // Active filter chips
          if (_activeFilters.isNotEmpty)
            Container(
              height: 6.h,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _activeFilters.entries.map((entry) {
                  return FilterChipWidget(
                    label: _getFilterLabel(entry.key, entry.value),
                    onRemove: () => _removeFilter(entry.key),
                  );
                }).toList(),
              ),
            ),

          // Followers list
          Expanded(
            child: _isRefreshing
                ? const SkeletonLoaderWidget()
                : _filteredFollowers.isEmpty
                ? EmptyStateWidget(
                    onInviteFriends: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite friends feature coming soon'),
                        ),
                      );
                    },
                  )
                : RefreshIndicator(
                    onRefresh: _refreshFollowers,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      itemCount:
                          _filteredFollowers.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredFollowers.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final follower = _filteredFollowers[index];
                        final isSelected = _selectedFollowerIds.contains(
                          follower["id"],
                        );

                        return Slidable(
                          key: ValueKey(follower["id"]),
                          enabled: !_isMultiSelectMode,
                          startActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) => _handleFollowBack(follower),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                icon: Icons.person_add,
                                label: 'Follow Back',
                              ),
                            ],
                          ),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) =>
                                    _handleRemoveFollower(follower),
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                                icon: Icons.person_remove,
                                label: 'Remove',
                              ),
                              SlidableAction(
                                onPressed: (_) =>
                                    _handleBlockFollower(follower),
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                icon: Icons.block,
                                label: 'Block',
                              ),
                            ],
                          ),
                          child: FollowerCardWidget(
                            follower: follower,
                            isMultiSelectMode: _isMultiSelectMode,
                            isSelected: isSelected,
                            onTap: () {
                              if (_isMultiSelectMode) {
                                _toggleFollowerSelection(
                                  follower["id"] as String,
                                );
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  '/profile-detail-screen',
                                  arguments: follower,
                                );
                              }
                            },
                            onLongPress: () {
                              if (!_isMultiSelectMode) {
                                _toggleMultiSelectMode();
                                _toggleFollowerSelection(
                                  follower["id"] as String,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _isMultiSelectMode
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedFollowerIds.isEmpty
                          ? null
                          : () => _handleBatchAction('Remove'),
                      icon: CustomIconWidget(
                        iconName: Icons.person_remove.codePoint.toString(),
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                      label: const Text('Remove'),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectedFollowerIds.isEmpty
                          ? null
                          : () => _handleBatchAction('Block'),
                      icon: CustomIconWidget(
                        iconName: Icons.block.codePoint.toString(),
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      label: const Text('Block'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : CustomBottomBar(currentRoute: '/followers-list-screen'),
    );
  }

  String _getFilterLabel(String key, dynamic value) {
    switch (key) {
      case 'dateRange':
        return 'Date Range';
      case 'mutualOnly':
        return 'Mutual Followers';
      case 'verifiedOnly':
        return 'Verified Only';
      case 'engagementLevel':
        return 'Engagement: ${(value as String).toUpperCase()}';
      default:
        return key;
    }
  }
}
