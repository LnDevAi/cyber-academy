import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final targuiApiProvider = Provider<TARGUIApi>((ref) {
  return TARGUIApi(ref.read(apiClientProvider));
});

class TARGUIApi {
  final ApiClient _client;
  TARGUIApi(this._client);

  Future<List<dynamic>> listSessions() async {
    final response = await _client.get('/targui/sessions/');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSession({String? enrollmentId}) async {
    final response = await _client.post('/targui/sessions/', data: {
      if (enrollmentId != null) 'enrollment_id': enrollmentId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMessages(String sessionId) async {
    final response = await _client.get('/targui/sessions/$sessionId/messages/');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required String content,
    String? context,
  }) async {
    final response = await _client.post(
      '/targui/sessions/$sessionId/messages/',
      data: {
        'content': content,
        if (context != null) 'context': context,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.delete('/targui/sessions/$sessionId/');
  }
}
