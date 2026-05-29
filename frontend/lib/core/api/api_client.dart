import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'http://localhost:8000/api/v1';
const String kTokenKey = 'auth_token';
const String kRefreshTokenKey = 'refresh_token';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(AuthInterceptor(_dio));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _log('$obj'),
    ));
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) async {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) async {
    return _dio.delete<T>(path);
  }
}

class AuthInterceptor extends Interceptor {
  final Dio dio;

  AuthInterceptor(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refresh
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(kRefreshTokenKey);
      if (refreshToken != null) {
        try {
          final response = await Dio().post(
            '$kBaseUrl/auth/token/refresh/',
            data: {'refresh': refreshToken},
          );
          final newToken = response.data['access'];
          await prefs.setString(kTokenKey, newToken);
          // Retry original request
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        } catch (_) {
          await prefs.remove(kTokenKey);
          await prefs.remove(kRefreshTokenKey);
          // Navigate to login — handled by router redirect
        }
      }
    }
    handler.next(err);
  }
}

// Helper to extract error message from DioException
String extractApiError(DioException e) {
  if (e.response?.data != null) {
    final data = e.response!.data;
    if (data is Map) {
      // Try common error fields
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      // Flatten field errors
      final msgs = <String>[];
      data.forEach((key, value) {
        if (value is List) msgs.add('$key: ${value.join(', ')}');
        else msgs.add('$key: $value');
      });
      if (msgs.isNotEmpty) return msgs.join('\n');
    }
    return data.toString();
  }
  if (e.type == DioExceptionType.connectionTimeout) {
    return 'Délai de connexion dépassé. Vérifiez votre connexion internet.';
  }
  if (e.type == DioExceptionType.connectionError) {
    return 'Impossible de se connecter au serveur. Vérifiez votre connexion.';
  }
  return e.message ?? 'Une erreur est survenue';
}

void _log(String message) {
  // ignore: avoid_print
  print('[CyberAcademy] $message');
}
