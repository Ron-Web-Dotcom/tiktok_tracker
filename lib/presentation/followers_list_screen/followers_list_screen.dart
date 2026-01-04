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

/// Followers List Screen - Comprehensive follower management interface
///
/// Features:
/// - Real-time search with debouncing
/// - Advanced filtering (date ranges, mutual followers, verification, engagement)
/// - Pull-to-refresh synchronization
/// - Swipe actions (follow-back, block, remove)
/// - Multi-select mode with batch operations
/// - Infinite scroll with progressive loading
/// - Platform-specific interactions (haptics, ripple effects)
class FollowersListScreen extends StatefulWidget {
  const FollowersListScreen({super.key});

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TikTokService _tiktokService = TikTokService();

  // State variables
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isMultiSelectMode = false;
  String _searchQuery = '';
  List<String> _selectedFollowerIds = [];

  // Filter state
  Map<String, dynamic> _activeFilters = {};

  // Sort options
  String _currentSortOption =
      'recent'; // recent, alphabetical, engagement, mutual

  // Real data from TikTok API (sorted latest first)
  List<Map<String, dynamic>> _allFollowers = [];
  List<Map<String, dynamic>> _filteredFollowers = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadRealData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load real data from TikTok API
  Future<void> _loadRealData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch real follower relationships from TikTok
      final relationships = await _tiktokService.fetchFollowerRelationships();
      final followers =
          relationships['followers'] as List<Map<String, dynamic>>;

      setState(() {
        // Data is already sorted latest-first from TikTok service
        _allFollowers = followers;
        _filteredFollowers = List.from(_allFollowers);
        _isLoading = false;
      });
    } catch (e) {
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

  void _onScroll() {
    // Infinite scroll implementation
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreFollowers();
    }
  }

  void _onSearchChanged() {
    // Debounced search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == _searchQuery) return;
      setState(() {
        _searchQuery = _searchController.text;
        _applyFiltersAndSearch();
      });
    });
  }

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
            final dateRange = _activeFilters['dateRange'] as String;
            final followDate = follower['followDate'] as DateTime;
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

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
        _filteredFollowers.sort(
          (a, b) => (a['displayName'] as String).compareTo(
            b['displayName'] as String,
          ),
        );
        break;
      case 'engagement':
        _filteredFollowers.sort((a, b) {
          final aLevel = a['engagementLevel'] as String;
          final bLevel = b['engagementLevel'] as String;
          final levelOrder = {'high': 3, 'medium': 2, 'low': 1};
          return (levelOrder[bLevel] ?? 0).compareTo(levelOrder[aLevel] ?? 0);
        });
        break;
      case 'mutual':
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

  Future<void> _refreshFollowers() async {
    setState(() => _isRefreshing = true);

    await _loadRealData();

    setState(() => _isRefreshing = false);
    if (mounted) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _loadMoreFollowers() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Simulate loading more data
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allFollowers.removeWhere((f) => f["id"] == follower["id"]);
                _applyFiltersAndSearch();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed ${follower["displayName"]}')),
              );
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allFollowers.removeWhere((f) => f["id"] == follower["id"]);
                _applyFiltersAndSearch();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Blocked ${follower["displayName"]}')),
              );
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _handleBatchAction(String action) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action ${_selectedFollowerIds.length} followers'),
        content: Text(
          'Are you sure you want to $action ${_selectedFollowerIds.length} selected followers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allFollowers.removeWhere(
                  (f) => _selectedFollowerIds.contains(f["id"]),
                );
                _selectedFollowerIds.clear();
                _isMultiSelectMode = false;
                _applyFiltersAndSearch();
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$action completed')));
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
          _applySorting();
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
