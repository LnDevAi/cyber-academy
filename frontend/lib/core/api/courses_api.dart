import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final coursesApiProvider = Provider<CoursesApi>((ref) {
  return CoursesApi(ref.read(apiClientProvider));
});

class CoursesApi {
  final ApiClient _client;
  CoursesApi(this._client);

  Future<List<dynamic>> getCatalogue({
    String? bloc,
    String? type,
    String? niveau,
    String? search,
    double? prixMin,
    double? prixMax,
  }) async {
    final params = <String, dynamic>{};
    if (bloc != null) params['bloc'] = bloc;
    if (type != null) params['type'] = type;
    if (niveau != null) params['niveau'] = niveau;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (prixMin != null) params['prix_min'] = prixMin;
    if (prixMax != null) params['prix_max'] = prixMax;

    final response = await _client.get('/courses/', queryParameters: params);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getCourseDetail(String code) async {
    final response = await _client.get('/courses/$code/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getLabs(String courseCode) async {
    final response = await _client.get('/courses/$courseCode/labs/');
    return response.data as List<dynamic>;
  }
}
