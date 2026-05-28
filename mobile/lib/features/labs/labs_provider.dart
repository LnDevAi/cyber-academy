import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../shared/models/user.dart';

// ── Labs list ──────────────────────────────────────────────────────────────

final labsListProvider = FutureProvider<List<Lab>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/labs/');
    final data = response.data;
    final list = data is List ? data : (data['results'] ?? data['labs'] ?? []);
    return (list as List).map((j) => Lab.fromJson(j as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw extractApiError(e);
  }
});

// ── Lab detail ─────────────────────────────────────────────────────────────

final labDetailProvider = FutureProvider.family<Lab, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/labs/$id/');
    return Lab.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw extractApiError(e);
  }
});

// ── Lab session ────────────────────────────────────────────────────────────

class LabSessionState {
  final bool isLoading;
  final Map<String, dynamic>? session;
  final String? error;

  const LabSessionState({
    this.isLoading = false,
    this.session,
    this.error,
  });

  LabSessionState copyWith({
    bool? isLoading,
    Map<String, dynamic>? session,
    String? error,
    bool clearError = false,
  }) {
    return LabSessionState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LabSessionNotifier extends StateNotifier<LabSessionState> {
  final ApiClient _api;

  LabSessionNotifier(this._api) : super(const LabSessionState());

  Future<bool> startSession(String labId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post('/labs/$labId/sessions/');
      state = state.copyWith(
        isLoading: false,
        session: response.data as Map<String, dynamic>,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractApiError(e),
      );
      return false;
    }
  }

  Future<bool> stopSession(String labId, String sessionId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _api.post('/labs/$labId/sessions/$sessionId/stop/');
      state = const LabSessionState();
      return true;
    } on DioException catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final labSessionProvider = StateNotifierProvider<LabSessionNotifier, LabSessionState>((ref) {
  return LabSessionNotifier(ref.read(apiClientProvider));
});

// ── Filters ────────────────────────────────────────────────────────────────

class LabFilters {
  final String? difficulty;
  final String? technology;
  final String? search;

  const LabFilters({this.difficulty, this.technology, this.search});

  LabFilters copyWith({String? difficulty, String? technology, String? search}) {
    return LabFilters(
      difficulty: difficulty ?? this.difficulty,
      technology: technology ?? this.technology,
      search: search ?? this.search,
    );
  }
}

final labFiltersProvider = StateProvider<LabFilters>((ref) => const LabFilters());

final filteredLabsProvider = Provider<AsyncValue<List<Lab>>>((ref) {
  final labs = ref.watch(labsListProvider);
  final filters = ref.watch(labFiltersProvider);

  return labs.when(
    data: (list) {
      var filtered = list;
      if (filters.difficulty != null && filters.difficulty!.isNotEmpty) {
        filtered = filtered.where((l) => l.difficulty == filters.difficulty).toList();
      }
      if (filters.technology != null && filters.technology!.isNotEmpty) {
        filtered = filtered.where((l) => l.technology == filters.technology).toList();
      }
      if (filters.search != null && filters.search!.isNotEmpty) {
        final q = filters.search!.toLowerCase();
        filtered = filtered
            .where((l) =>
                l.title.toLowerCase().contains(q) ||
                l.description.toLowerCase().contains(q))
            .toList();
      }
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
