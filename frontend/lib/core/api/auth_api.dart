import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(apiClientProvider));
});

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String nomComplet,
    required String email,
    required String telephone,
    required String password,
    required String passwordConfirm,
    required String profil,
  }) async {
    final response = await _client.post('/auth/register/', data: {
      'nom_complet': nomComplet,
      'email': email,
      'telephone': telephone,
      'password': password,
      'password_confirm': passwordConfirm,
      'profil': profil,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _client.get('/auth/me/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setup2FA() async {
    final response = await _client.post('/auth/2fa/setup/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verify2FA({required String code}) async {
    final response = await _client.post('/auth/2fa/verify/', data: {'code': code});
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout/');
    } catch (_) {
      // Ignore logout errors
    }
  }

  Future<Map<String, dynamic>> refreshToken({required String refreshToken}) async {
    final response = await _client.post('/auth/token/refresh/', data: {
      'refresh': refreshToken,
    });
    return response.data as Map<String, dynamic>;
  }
}
