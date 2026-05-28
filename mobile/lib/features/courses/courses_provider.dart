import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../shared/models/user.dart';

// ── Courses list ───────────────────────────────────────────────────────────

final coursesListProvider = FutureProvider<List<Course>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/courses/');
    final data = response.data;
    final list = data is List ? data : (data['results'] ?? data['courses'] ?? []);
    return (list as List).map((j) => Course.fromJson(j as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw extractApiError(e);
  }
});

// ── Course detail ──────────────────────────────────────────────────────────

final courseDetailProvider = FutureProvider.family<Course, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/courses/$id/');
    return Course.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw extractApiError(e);
  }
});

// ── Lessons list ───────────────────────────────────────────────────────────

final lessonsProvider = FutureProvider.family<List<Lesson>, String>((ref, courseId) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/courses/$courseId/lessons/');
    final data = response.data;
    final list = data is List ? data : (data['results'] ?? data['lessons'] ?? []);
    return (list as List).map((j) => Lesson.fromJson(j as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw extractApiError(e);
  }
});

// ── Lesson detail ──────────────────────────────────────────────────────────

final lessonDetailProvider = FutureProvider.family<Lesson, ({String courseId, String lessonId})>(
  (ref, params) async {
    final api = ref.read(apiClientProvider);
    try {
      final response = await api.get('/courses/${params.courseId}/lessons/${params.lessonId}/');
      return Lesson.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw extractApiError(e);
    }
  },
);

// ── Enrollment ─────────────────────────────────────────────────────────────

class EnrollmentNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _api;

  EnrollmentNotifier(this._api) : super(const AsyncValue.data(null));

  Future<bool> enroll(String courseId) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/courses/$courseId/enroll/');
      state = const AsyncValue.data(null);
      return true;
    } on DioException catch (e) {
      state = AsyncValue.error(extractApiError(e), StackTrace.current);
      return false;
    }
  }

  Future<bool> markLessonComplete(String courseId, String lessonId) async {
    try {
      await _api.post('/courses/$courseId/lessons/$lessonId/complete/');
      return true;
    } on DioException catch (_) {
      return false;
    }
  }
}

final enrollmentProvider = StateNotifierProvider<EnrollmentNotifier, AsyncValue<void>>((ref) {
  return EnrollmentNotifier(ref.read(apiClientProvider));
});

// ── Filters ────────────────────────────────────────────────────────────────

class CourseFilters {
  final String? level;
  final String? category;
  final String? search;

  const CourseFilters({this.level, this.category, this.search});

  CourseFilters copyWith({String? level, String? category, String? search}) {
    return CourseFilters(
      level: level ?? this.level,
      category: category ?? this.category,
      search: search ?? this.search,
    );
  }
}

final courseFiltersProvider = StateProvider<CourseFilters>((ref) => const CourseFilters());

final filteredCoursesProvider = Provider<AsyncValue<List<Course>>>((ref) {
  final courses = ref.watch(coursesListProvider);
  final filters = ref.watch(courseFiltersProvider);

  return courses.when(
    data: (list) {
      var filtered = list;
      if (filters.level != null && filters.level!.isNotEmpty) {
        filtered = filtered.where((c) => c.level == filters.level).toList();
      }
      if (filters.category != null && filters.category!.isNotEmpty) {
        filtered = filtered.where((c) => c.category == filters.category).toList();
      }
      if (filters.search != null && filters.search!.isNotEmpty) {
        final q = filters.search!.toLowerCase();
        filtered = filtered.where((c) =>
          c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q),
        ).toList();
      }
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
