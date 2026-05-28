import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/courses/courses_catalog_screen.dart';
import '../features/courses/course_detail_screen.dart';
import '../features/courses/lesson_screen.dart';
import '../features/labs/labs_list_screen.dart';
import '../features/labs/lab_detail_screen.dart';
import '../features/certifications/certifications_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;

      if (isLoading) return null;

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/courses',
        name: 'courses',
        builder: (context, state) => const CoursesCatalogScreen(),
      ),
      GoRoute(
        path: '/courses/:id',
        name: 'course-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CourseDetailScreen(courseId: id);
        },
      ),
      GoRoute(
        path: '/courses/:id/learn',
        name: 'lesson',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final lessonId = state.uri.queryParameters['lessonId'];
          return LessonScreen(courseId: id, lessonId: lessonId);
        },
      ),
      GoRoute(
        path: '/labs',
        name: 'labs',
        builder: (context, state) => const LabsListScreen(),
      ),
      GoRoute(
        path: '/labs/:id',
        name: 'lab-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LabDetailScreen(labId: id);
        },
      ),
      GoRoute(
        path: '/certifications',
        name: 'certifications',
        builder: (context, state) => const CertificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page introuvable',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.error.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text("Retour à l'accueil"),
            ),
          ],
        ),
      ),
    ),
  );
});
