import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String kBaseUrl = 'http://api.academy.edefence.tech/api/v1';
const String kTokenKey = 'access_token';
const String kRefreshTokenKey = 'refresh_token';

final _secureStorage = const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

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
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
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
    final token = await _secureStorage.read(key: kTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _secureStorage.read(key: kRefreshTokenKey);
      if (refreshToken != null) {
        try {
          final response = await Dio().post(
            '$kBaseUrl/auth/token/refresh/',
            data: {'refresh': refreshToken},
          );
          final newToken = response.data['access'];
          await _secureStorage.write(key: kTokenKey, value: newToken);
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        } catch (_) {
          await _secureStorage.delete(key: kTokenKey);
          await _secureStorage.delete(key: kRefreshTokenKey);
        }
      }
    }
    handler.next(err);
  }
}

String extractApiError(DioException e) {
  if (e.response?.data != null) {
    final data = e.response!.data;
    if (data is Map) {
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      final msgs = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          msgs.add('$key: ${value.join(', ')}');
        } else {
          msgs.add('$key: $value');
        }
      });
      if (msgs.isNotEmpty) return msgs.join('\n');
    }
    return data.toString();
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return 'Délai de connexion dépassé. Vérifiez votre connexion internet.';
    case DioExceptionType.connectionError:
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion.';
    case DioExceptionType.receiveTimeout:
      return 'Le serveur met trop de temps à répondre. Réessayez plus tard.';
    default:
      return e.message ?? 'Une erreur inattendue est survenue.';
  }
}
