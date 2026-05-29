import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/cyber_range_api.dart';
import '../../shared/models/cyber_range_session.dart';

class RangeSessionState {
  final CyberRangeSession? session;
  final bool isLoading;
  final String? error;
  final int elapsedSeconds;

  const RangeSessionState({
    this.session,
    this.isLoading = false,
    this.error,
    this.elapsedSeconds = 0,
  });

  RangeSessionState copyWith({
    CyberRangeSession? session,
    bool? isLoading,
    String? error,
    int? elapsedSeconds,
  }) {
    return RangeSessionState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

class RangeSessionNotifier extends StateNotifier<RangeSessionState> {
  final CyberRangeApi _api;
  final String labId;
  final String enrollmentId;
  Timer? _timer;
  Timer? _pollTimer;

  RangeSessionNotifier({
    required CyberRangeApi api,
    required this.labId,
    required this.enrollmentId,
  })  : _api = api,
        super(const RangeSessionState()) {
    _startSession();
  }

  Future<void> _startSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _api.startSession(
        labId: labId,
        enrollmentId: enrollmentId,
      );
      final session = CyberRangeSession.fromJson(data);
      state = state.copyWith(session: session, isLoading: false);

      if (session.isActive || session.isDemarrage) {
        _startTimer();
        _startPolling();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de démarrer la session: $e',
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (state.session != null && mounted) {
        try {
          final data = await _api.getSessionStatus(state.session!.id);
          final updated = CyberRangeSession.fromJson(data);
          state = state.copyWith(session: updated);
          if (updated.isTermine) {
            _pollTimer?.cancel();
            _timer?.cancel();
          }
        } catch (_) {}
      }
    });
  }

  Future<void> stopSession() async {
    if (state.session == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await _api.stopSession(state.session!.id);
      _timer?.cancel();
      _pollTimer?.cancel();
      state = state.copyWith(
        isLoading: false,
        session: CyberRangeSession(
          id: state.session!.id,
          labId: state.session!.labId,
          enrollmentId: state.session!.enrollmentId,
          userId: state.session!.userId,
          statut: 'termine',
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String get formattedTime {
    final h = state.elapsedSeconds ~/ 3600;
    final m = (state.elapsedSeconds % 3600) ~/ 60;
    final s = state.elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}

final rangeSessionProvider = StateNotifierProvider.autoDispose
    .family<RangeSessionNotifier, RangeSessionState, (String, String)>(
  (ref, args) {
    final api = ref.read(cyberRangeApiProvider);
    return RangeSessionNotifier(
      api: api,
      labId: args.$1,
      enrollmentId: args.$2,
    );
  },
);

final labHintsProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, labId) async {
  final api = ref.read(cyberRangeApiProvider);
  try {
    final data = await api.getLabHints(labId);
    return List<String>.from(data);
  } catch (_) {
    return [
      'Commencez par une reconnaissance passive (OSINT)',
      'Utilisez nmap avec les flags -sV -sC pour la détection de services',
      'Vérifiez les credentials par défaut des services découverts',
    ];
  }
});
