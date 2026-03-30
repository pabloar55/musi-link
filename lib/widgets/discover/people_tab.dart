import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:musi_link/widgets/user_discovery_card.dart';
import 'package:musi_link/models/discovery_result.dart';

class PeopleTab extends StatefulWidget {
  final List<DiscoveryResult> results;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasError;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  const PeopleTab({
    super.key,
    required this.results,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.hasError,
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.hasError) {
      return Center(
        child: Text(
          l10n.discoverErrorLoading,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (widget.results.isEmpty) {
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
                l10n.discoverNoUsers,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.discoverNoUsersHint,
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
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: widget.results.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.results.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: widget.isLoadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          }
          final result = widget.results[index];
          return UserDiscoveryCard(
            result: result,
            onTap: () => context.push('/profile', extra: result.user),
          );
        },
      ),
    );
  }
}
