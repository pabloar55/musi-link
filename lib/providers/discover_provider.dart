import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/models/discovery_result.dart';
import 'package:musi_link/providers/service_providers.dart';
import 'package:musi_link/utils/error_reporter.dart';

class DiscoverState {
  const DiscoverState({
    this.results = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
  });

  final List<DiscoveryResult> results;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get hasError => error != null;

  DiscoverState copyWith({
    List<DiscoveryResult>? results,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error = _sentinel,
  }) {
    return DiscoverState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _sentinel) ? this.error : error,
    );
  }
}

const _sentinel = Object();

class DiscoverNotifier extends Notifier<DiscoverState> {
  @override
  DiscoverState build() => const DiscoverState();

  Future<void> loadDiscovery({bool forceRefresh = false}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      results: forceRefresh ? [] : null,
    );

    try {
      final service = ref.read(musicProfileServiceProvider);
      final results = await service.getDiscoveryUsers(forceRefresh: forceRefresh);

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasMore: service.hasMoreDiscoveryUsers,
      );
    } catch (e, stack) {
      await reportError(e, stack);
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  Future<void> refresh() => loadDiscovery(forceRefresh: true);

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final (allResults, hasMore) =
          await ref.read(musicProfileServiceProvider).loadMoreDiscoveryUsers();

      state = state.copyWith(
        results: allResults,
        isLoadingMore: false,
        hasMore: hasMore,
      );
    } catch (e, stack) {
      await reportError(e, stack);
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final discoverProvider =
    NotifierProvider<DiscoverNotifier, DiscoverState>(DiscoverNotifier.new);
