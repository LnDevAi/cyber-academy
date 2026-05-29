import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/targui_api.dart';
import '../../shared/models/chat_message.dart';

class TARGUIState {
  final List<TarguiSession> sessions;
  final String? activeSessionId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? error;

  const TARGUIState({
    this.sessions = const [],
    this.activeSessionId,
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.error,
  });

  TARGUIState copyWith({
    List<TarguiSession>? sessions,
    String? activeSessionId,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isTyping,
    String? error,
  }) {
    return TARGUIState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      error: error,
    );
  }
}

class TARGUINotifier extends StateNotifier<TARGUIState> {
  final TARGUIApi _api;

  TARGUINotifier(this._api) : super(const TARGUIState()) {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _api.listSessions();
      final sessions = data
          .map((d) => TarguiSession.fromJson(d as Map<String, dynamic>))
          .toList();
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, sessions: []);
    }
  }

  Future<void> newSession({String? enrollmentId}) async {
    try {
      final data = await _api.createSession(enrollmentId: enrollmentId);
      final session = TarguiSession.fromJson(data);
      state = state.copyWith(
        sessions: [session, ...state.sessions],
        activeSessionId: session.id,
        messages: [],
      );
    } catch (_) {
      // Offline fallback
      const fakeId = 'local-session';
      state = state.copyWith(activeSessionId: fakeId, messages: []);
    }
  }

  Future<void> selectSession(String sessionId) async {
    state = state.copyWith(activeSessionId: sessionId, isLoading: true);
    try {
      final data = await _api.getMessages(sessionId);
      final msgs = data
          .map((d) => ChatMessage.fromJson(d as Map<String, dynamic>))
          .toList();
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state.activeSessionId == null) {
      await newSession();
    }

    final userMsg = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: state.activeSessionId ?? '',
      role: 'user',
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      id: 'loading-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: state.activeSessionId ?? '',
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isTyping: true,
    );

    try {
      final data = await _api.sendMessage(
        sessionId: state.activeSessionId!,
        content: content,
      );
      final responseMsg = ChatMessage.fromJson(data);
      final updatedMessages = state.messages.where((m) => !m.isLoading).toList()
        ..add(responseMsg);
      state = state.copyWith(messages: updatedMessages, isTyping: false);
    } catch (_) {
      // Fallback response
      final fallback = ChatMessage(
        id: 'fallback-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: state.activeSessionId ?? '',
        role: 'assistant',
        content: 'Je suis en mode hors ligne. Veuillez vérifier votre connexion internet pour accéder à TARGUI.',
        createdAt: DateTime.now(),
      );
      final updatedMessages = state.messages.where((m) => !m.isLoading).toList()
        ..add(fallback);
      state = state.copyWith(messages: updatedMessages, isTyping: false);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _api.deleteSession(sessionId);
      final sessions = state.sessions.where((s) => s.id != sessionId).toList();
      state = state.copyWith(
        sessions: sessions,
        activeSessionId: sessions.isNotEmpty ? sessions.first.id : null,
        messages: [],
      );
    } catch (_) {}
  }
}

final targuiProvider = StateNotifierProvider<TARGUINotifier, TARGUIState>((ref) {
  final api = ref.read(targuiApiProvider);
  return TARGUINotifier(api);
});
