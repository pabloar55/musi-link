import 'package:flutter/material.dart';
import 'package:musi_link/components/user_discovery_card.dart';
import 'package:musi_link/core/models/discovery_result.dart';
import 'package:musi_link/core/music_profile_service.dart';
import 'package:musi_link/screens/user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen> {
  late Future<List<DiscoveryResult>> _discoveryFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDiscovery();
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
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<DiscoveryResult>>(
      future: _discoveryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar descubrimiento',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_off,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay usuarios con datos musicales',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuando mas usuarios conecten su Spotify, aparecerán aqui',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return UserDiscoveryCard(
                result: result,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(user: result.user),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
