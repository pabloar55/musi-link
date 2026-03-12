import 'package:flutter/material.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/services/music_profile_service.dart';
import 'package:musi_link/widgets/discover/people_tab.dart';
import 'package:musi_link/widgets/discover/daily_song_tab.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
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
    _discoveryFuture = MusicProfileService.instance.getDiscoveryUsers();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadDiscovery();
    });
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
            Tab(text: l10n.discoverTabDailySong),
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

