import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final cyberRangeApiProvider = Provider<CyberRangeApi>((ref) {
  return CyberRangeApi(ref.read(apiClientProvider));
});

class CyberRangeApi {
  final ApiClient _client;
  CyberRangeApi(this._client);

  Future<Map<String, dynamic>> startSession({
    required String labId,
    required String enrollmentId,
  }) async {
    final response = await _client.post('/cyber-range/sessions/start/', data: {
      'lab_id': labId,
      'enrollment_id': enrollmentId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> stopSession(String sessionId) async {
    final response = await _client.post('/cyber-range/sessions/$sessionId/stop/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSessionStatus(String sessionId) async {
    final response = await _client.get('/cyber-range/sessions/$sessionId/status/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listActiveSessions() async {
    final response = await _client.get('/cyber-range/sessions/active/');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getLabDetails(String labId) async {
    final response = await _client.get('/cyber-range/labs/$labId/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getLabHints(String labId) async {
    final response = await _client.get('/cyber-range/labs/$labId/hints/');
    return response.data as List<dynamic>;
  }
}
