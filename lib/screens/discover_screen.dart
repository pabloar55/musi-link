import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/widgets/discover/people_tab.dart';
import 'package:musi_link/widgets/discover/daily_song_tab.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with AutomaticKeepAliveClientMixin<DiscoverScreen>, TickerProviderStateMixin {
  late TabController _tabController;

  List<DiscoveryResult> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_loadDiscovery());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscovery({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (forceRefresh) _results = [];
    });
    try {
      final service = ref.read(musicProfileServiceProvider);
      final results = await service.getDiscoveryUsers(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _hasMore = service.hasMoreDiscoveryUsers;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  Future<void> _refresh() => _loadDiscovery(forceRefresh: true);

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final (allResults, hasMore) =
          await ref.read(musicProfileServiceProvider).loadMoreDiscoveryUsers();
      if (!mounted) return;
      setState(() {
        _results = allResults;
        _isLoadingMore = false;
        _hasMore = hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        TabBar(
          splashFactory: NoSplash.splashFactory,
          dividerColor: Colors.transparent,
          controller: _tabController,
          tabs: [
            Tab(text: l10n.discoverTabPeople),
            Tab(text: l10n.dailySongTitle),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              PeopleTab(
                results: _results,
                isLoading: _isLoading,
                isLoadingMore: _isLoadingMore,
                hasMore: _hasMore,
                hasError: _error != null,
                onRefresh: _refresh,
                onLoadMore: _loadMore,
              ),
              const DailySongTab(),
            ],
          ),
        ),
      ],
    );
  }
}
