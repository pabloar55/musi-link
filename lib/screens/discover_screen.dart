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
  late Future<List<DiscoveryResult>> _discoveryFuture;
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDiscovery();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDiscovery() {
    _discoveryFuture = ref.read(musicProfileServiceProvider).getDiscoveryUsers();
  }

  Future<void> _refresh() async {
    setState(_loadDiscovery);
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
                discoveryFuture: _discoveryFuture,
                onRefresh: _refresh,
              ),
              const DailySongTab(),
            ],
          ),
        ),
      ],
    );
  }
}

