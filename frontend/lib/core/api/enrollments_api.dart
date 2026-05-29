import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final enrollmentsApiProvider = Provider<EnrollmentsApi>((ref) {
  return EnrollmentsApi(ref.read(apiClientProvider));
});

class EnrollmentsApi {
  final ApiClient _client;
  EnrollmentsApi(this._client);

  Future<List<dynamic>> listEnrollments() async {
    final response = await _client.get('/enrollments/');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getEnrollment(String enrollmentId) async {
    final response = await _client.get('/enrollments/$enrollmentId/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enroll({required String courseCode}) async {
    final response = await _client.post('/enrollments/', data: {
      'course_code': courseCode,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProgress({
    required String enrollmentId,
    required String moduleId,
    required double progress,
  }) async {
    final response = await _client.patch('/enrollments/$enrollmentId/progress/', data: {
      'module_id': moduleId,
      'progress': progress,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getModules(String enrollmentId) async {
    final response = await _client.get('/enrollments/$enrollmentId/modules/');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getResources(String enrollmentId) async {
    final response = await _client.get('/enrollments/$enrollmentId/resources/');
    return response.data as List<dynamic>;
  }
}
