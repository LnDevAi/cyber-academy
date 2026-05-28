import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../shared/models/user.dart';

// ── User certifications ────────────────────────────────────────────────────

final certificationsProvider = FutureProvider<List<Certification>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/certifications/');
    final data = response.data;
    final list = data is List ? data : (data['results'] ?? data['certifications'] ?? []);
    return (list as List)
        .map((j) => Certification.fromJson(j as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw extractApiError(e);
  }
});

// ── Available certifications ───────────────────────────────────────────────

final availableCertificationsProvider = FutureProvider<List<Certification>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/certifications/available/');
    final data = response.data;
    final list = data is List ? data : (data['results'] ?? []);
    return (list as List)
        .map((j) => Certification.fromJson(j as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw extractApiError(e);
  }
});
