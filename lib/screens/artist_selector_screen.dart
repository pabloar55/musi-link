import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/models/artist.dart';
import 'package:musi_link/providers/firebase_providers.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/router/go_router_provider.dart';
import 'package:musi_link/screens/onboarding_screen.dart';
import 'package:musi_link/utils/error_reporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArtistSelectorScreen extends ConsumerStatefulWidget {
  const ArtistSelectorScreen({super.key, this.isEditMode = false});

  final bool isEditMode;

  @override
  ConsumerState<ArtistSelectorScreen> createState() =>
      _ArtistSelectorScreenState();
}

class _ArtistSelectorScreenState extends ConsumerState<ArtistSelectorScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<Artist> _searchResults = [];
  List<Artist> _suggestions = [];
  final List<Artist> _selected = [];

  bool _isSearching = false;
  bool _isSaving = false;
  Timer? _debounce;
  String _lastQuery = '';

  static const _minArtists = 3;
  static const _maxArtists = 15;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    if (widget.isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingArtists());
    }
  }

  Future<void> _loadExistingArtists() async {
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return;
      final user = await ref.read(userServiceProvider).getUser(uid);
      if (!mounted || user == null) return;
      setState(() => _selected.addAll(user.topArtists));
    } catch (e, st) {
      reportError(e, st).ignore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query == _lastQuery) return;
    _lastQuery = query;
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final results = await ref
          .read(spotifyStatsProvider)
          .searchArtists(query, limit: 20);
      if (!mounted) return;
      setState(() {
        _searchResults = results
            .where((a) => !_selected.any((s) => s.name == a.name))
            .toList();
        _isSearching = false;
      });
    } catch (e, st) {
      reportError(e, st).ignore();
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  Future<void> _loadSuggestions() async {
    if (_selected.isEmpty) return;
    try {
      final service = ref.read(spotifyStatsProvider);
      final results = await Future.wait(
        _selected.map((a) => service.getRelatedArtists(a.name)),
      );
      if (!mounted) return;
      final seen = <String>{};
      final merged = <Artist>[];
      for (final list in results) {
        for (final a in list) {
          if (seen.add(a.name) && !_selected.any((s) => s.name == a.name)) {
            merged.add(a);
            if (merged.length >= 20) break;
          }
        }
        if (merged.length >= 20) break;
      }
      setState(() => _suggestions = merged);
    } catch (_) {}
  }

  void _toggleArtist(Artist artist) {
    final idx = _selected.indexWhere((a) => a.name == artist.name);
    if (idx >= 0) {
      setState(() {
        _selected.removeAt(idx);
        _searchResults = _searchResults
            .where((a) => !_selected.any((s) => s.name == a.name))
            .toList();
      });
    } else {
      if (_selected.length >= _maxArtists) return;
      setState(() {
        _selected.add(artist);
        _searchResults.removeWhere((a) => a.name == artist.name);
        _suggestions.removeWhere((a) => a.name == artist.name);
      });
      if (artist.imageUrl.isEmpty) _enrichFromSpotify(artist);
    }
    _loadSuggestions();
  }

  static String _normalizeName(String name) => name
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _enrichFromSpotify(Artist artist) async {
    try {
      final results = await ref
          .read(spotifyStatsProvider)
          .searchArtists(artist.name, limit: 1);
      if (!mounted || results.isEmpty) return;
      final enriched = results.first;
      if (_normalizeName(enriched.name) != _normalizeName(artist.name)) return;
      setState(() {
        final idx = _selected.indexWhere((a) => a.name == artist.name);
        if (idx >= 0) _selected[idx] = enriched;
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_selected.length < _minArtists) return;
    setState(() => _isSaving = true);
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return;

      await ref
          .read(musicProfileServiceProvider)
          .saveManualArtists(uid, _selected);

      final prefs = await SharedPreferences.getInstance();
      final onboardingDone =
          prefs.getBool(OnboardingScreen.onboardingCompletedKey) ?? false;
      if (!mounted) return;

      if (widget.isEditMode) {
        if (!mounted) return;
        context.pop();
      } else {
        ref.read(appRouterNotifierProvider).setArtistsSelected(
              onboardingDone: onboardingDone,
            );
      }
    } catch (e, st) {
      reportError(e, st).ignore();
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.genericError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final showSearch = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEditMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: BackButton(onPressed: () => context.pop()),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, widget.isEditMode ? 8 : 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.artistSelectorTitle,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.artistSelectorSubtitle(
                        _selected.length, _minArtists),
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.artistSelectorSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Selected chips
            if (_selected.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: _selected.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final a = _selected[i];
                    return InputChip(
                      avatar: a.imageUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage:
                                  CachedNetworkImageProvider(a.imageUrl),
                            )
                          : null,
                      label: Text(a.name),
                      onDeleted: () => _toggleArtist(a),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            // List
            Expanded(
              child: showSearch
                  ? _buildSearchResults(l10n)
                  : _buildSuggestions(l10n),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: (_selected.length >= _minArtists && !_isSaving)
                      ? _save
                      : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.artistSelectorContinue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(l10n.artistSelectorNoResults,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return _artistList(_searchResults);
  }

  Widget _buildSuggestions(AppLocalizations l10n) {
    if (_selected.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.artistSelectorEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.artistSelectorSuggested,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((artist) {
              return ActionChip(
                label: Text(artist.name),
                onPressed: () => _toggleArtist(artist),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _artistList(List<Artist> artists) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: artists.length,
      itemBuilder: (_, i) {
        final artist = artists[i];
        final isSelected = _selected.any((a) => a.name == artist.name);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: artist.imageUrl.isNotEmpty
                ? CachedNetworkImageProvider(artist.imageUrl)
                : null,
            child: artist.imageUrl.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(artist.name),
          subtitle: artist.genres.isNotEmpty
              ? Text(
                  artist.genres.take(3).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: isSelected
              ? Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary)
              : Icon(Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
          onTap: () => _toggleArtist(artist),
        );
      },
    );
  }
}
