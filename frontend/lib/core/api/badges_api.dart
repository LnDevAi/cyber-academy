import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final badgesApiProvider = Provider<BadgesApi>((ref) {
  return BadgesApi(ref.read(apiClientProvider));
});

class BadgesApi {
  final ApiClient _client;
  BadgesApi(this._client);

  Future<List<dynamic>> listBadges() async {
    final response = await _client.get('/badges/');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getBadge(String badgeId) async {
    final response = await _client.get('/badges/$badgeId/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyBadge(String badgeId) async {
    final response = await _client.get('/badges/$badgeId/verify/');
    return response.data as Map<String, dynamic>;
  }

  Future<String> getBadgeVerificationUrl(String badgeId) async {
    final response = await _client.get('/badges/$badgeId/verification-url/');
    return response.data['url'] as String;
  }

  Future<List<dynamic>> listAllBadges() async {
    final response = await _client.get('/admin/badges/');
    return response.data as List<dynamic>;
  }
}
