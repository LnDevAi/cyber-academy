import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_client.dart';
import '../../shared/models/user.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// ── State ──────────────────────────────────────────────────────────────────

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.read(key: kTokenKey);
    if (token != null) {
      await _loadUser();
    } else {
      state = const AuthState();
    }
  }

  Future<void> _loadUser() async {
    try {
      final response = await _api.get('/auth/me/');
      final user = User.fromJson(response.data as Map<String, dynamic>);
      state = AuthState(user: user, isAuthenticated: true);
    } catch (_) {
      await _storage.delete(key: kTokenKey);
      await _storage.delete(key: kRefreshTokenKey);
      state = const AuthState();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post('/auth/login/', data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      await _storage.write(
        key: kTokenKey,
        value: data['access'] ?? data['token'] ?? '',
      );
      if (data['refresh'] != null) {
        await _storage.write(key: kRefreshTokenKey, value: data['refresh']);
      }
      await _loadUser();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractApiError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Une erreur inattendue est survenue.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post('/auth/register/', data: {
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['access'] != null) {
        await _storage.write(key: kTokenKey, value: data['access']);
      }
      if (data['refresh'] != null) {
        await _storage.write(key: kRefreshTokenKey, value: data['refresh']);
      }
      await _loadUser();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractApiError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Une erreur inattendue est survenue.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout/');
    } catch (_) {}
    await _storage.delete(key: kTokenKey);
    await _storage.delete(key: kRefreshTokenKey);
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.read(apiClientProvider);
  return AuthNotifier(api);
});
