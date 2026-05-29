import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final mentorApiProvider = Provider<MentorApi>((ref) {
  return MentorApi(ref.read(apiClientProvider));
});

class MentorApi {
  final ApiClient _client;
  MentorApi(this._client);

  Future<List<dynamic>> listMentors() async {
    final response = await _client.get('/mentors/');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getMentor(String mentorId) async {
    final response = await _client.get('/mentors/$mentorId/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> scheduleSession({
    required String mentorId,
    required String enrollmentId,
    required DateTime dateHeure,
    required String sujet,
  }) async {
    final response = await _client.post('/mentor-sessions/', data: {
      'mentor_id': mentorId,
      'enrollment_id': enrollmentId,
      'date_heure': dateHeure.toIso8601String(),
      'sujet': sujet,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listSessions() async {
    final response = await _client.get('/mentor-sessions/');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> listMentorSessions() async {
    final response = await _client.get('/mentor/sessions/');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> listMentorApprenants() async {
    final response = await _client.get('/mentor/apprenants/');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> listLivrables() async {
    final response = await _client.get('/mentor/livrables/');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> corrigerLivrable({
    required String livrableId,
    required int note,
    required String commentaire,
  }) async {
    final response = await _client.post('/mentor/livrables/$livrableId/corriger/', data: {
      'note': note,
      'commentaire': commentaire,
    });
    return response.data as Map<String, dynamic>;
  }
}
