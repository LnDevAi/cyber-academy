import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/auth_api.dart';
import '../../shared/models/user.dart';

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
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;

  AuthNotifier(this._authApi) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kTokenKey);
    if (token != null) {
      await _loadUser();
    }
  }

  Future<void> _loadUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _authApi.me();
      final user = User.fromJson(data);
      state = AuthState(user: user, isAuthenticated: true);
    } catch (e) {
      state = const AuthState(isAuthenticated: false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authApi.login(email: email, password: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kTokenKey, data['access'] ?? data['token'] ?? '');
      if (data['refresh'] != null) {
        await prefs.setString(kRefreshTokenKey, data['refresh']);
      }
      await _loadUser();
      return true;
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String nomComplet,
    required String email,
    required String telephone,
    required String password,
    required String passwordConfirm,
    required String profil,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authApi.register(
        nomComplet: nomComplet,
        email: email,
        telephone: telephone,
        password: password,
        passwordConfirm: passwordConfirm,
        profil: profil,
      );
      final prefs = await SharedPreferences.getInstance();
      if (data['access'] != null) {
        await prefs.setString(kTokenKey, data['access']);
      }
      if (data['refresh'] != null) {
        await prefs.setString(kRefreshTokenKey, data['refresh']);
      }
      await _loadUser();
      return true;
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authApi.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kTokenKey);
    await prefs.remove(kRefreshTokenKey);
    state = const AuthState();
  }

  Future<Map<String, dynamic>?> setup2FA() async {
    try {
      return await _authApi.setup2FA();
    } catch (e) {
      return null;
    }
  }

  Future<bool> verify2FA(String code) async {
    try {
      await _authApi.verify2FA(code: code);
      await _loadUser();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApi = ref.read(authApiProvider);
  return AuthNotifier(authApi);
});
