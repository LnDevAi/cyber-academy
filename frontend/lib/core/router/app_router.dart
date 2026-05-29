import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/two_factor_setup_page.dart';
import '../../features/vitrine/vitrine_page.dart';
import '../../features/catalogue/catalogue_page.dart';
import '../../features/catalogue/cours_detail_page.dart';
import '../../features/dashboard_apprenant/dashboard_apprenant_page.dart';
import '../../features/dashboard_apprenant/parcour_detail_page.dart';
import '../../features/dashboard_apprenant/labs_list_page.dart';
import '../../features/cyber_range/cyber_range_page.dart';
import '../../features/badges/badges_page.dart';
import '../../features/targui/targui_page.dart';
import '../../features/paiement/paiement_page.dart';
import '../../features/paiement/paiement_confirmation_page.dart';
import '../../features/dashboard_mentor/dashboard_mentor_page.dart';
import '../../features/dashboard_admin/dashboard_admin_page.dart';
import '../../features/dashboard_b2b/dashboard_b2b_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/vitrine',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(kTokenKey);
      final isLoggedIn = token != null && authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isPublic = state.matchedLocation == '/vitrine' ||
          state.matchedLocation == '/catalogue' ||
          state.matchedLocation.startsWith('/catalogue/') ||
          isLoggingIn ||
          state.matchedLocation == '/2fa-setup' ||
          state.matchedLocation == '/2fa-verify';

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/vitrine',
      ),
      GoRoute(
        path: '/vitrine',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: VitrinePage()),
      ),
      GoRoute(
        path: '/catalogue',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: CataloguePage()),
      ),
      GoRoute(
        path: '/catalogue/:code',
        pageBuilder: (ctx, state) {
          final code = state.pathParameters['code']!;
          return NoTransitionPage(child: CoursDetailPage(courseCode: code));
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: RegisterPage()),
      ),
      GoRoute(
        path: '/2fa-setup',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: TwoFactorSetupPage()),
      ),
      GoRoute(
        path: '/2fa-verify',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: TwoFactorVerifyPage()),
      ),
      // Dashboard apprenant
      GoRoute(
        path: '/dashboard',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: DashboardApprenantPage()),
      ),
      GoRoute(
        path: '/dashboard/badges',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: BadgesPage()),
      ),
      GoRoute(
        path: '/dashboard/targui',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: TARGUIPage()),
      ),
      GoRoute(
        path: '/dashboard/parcours/:enrollmentId',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['enrollmentId']!;
          return NoTransitionPage(child: ParcourDetailPage(enrollmentId: id));
        },
      ),
      GoRoute(
        path: '/dashboard/parcours/:enrollmentId/labs',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['enrollmentId']!;
          return NoTransitionPage(child: LabsListPage(enrollmentId: id));
        },
      ),
      GoRoute(
        path: '/dashboard/parcours/:enrollmentId/labs/:labId',
        pageBuilder: (ctx, state) {
          final enrollmentId = state.pathParameters['enrollmentId']!;
          final labId = state.pathParameters['labId']!;
          return NoTransitionPage(
            child: CyberRangePage(enrollmentId: enrollmentId, labId: labId),
          );
        },
      ),
      // Paiement
      GoRoute(
        path: '/paiement/:enrollmentId',
        pageBuilder: (ctx, state) {
          final id = state.pathParameters['enrollmentId']!;
          return NoTransitionPage(child: PaiementPage(enrollmentId: id));
        },
      ),
      GoRoute(
        path: '/paiement/confirmation',
        pageBuilder: (ctx, state) {
          final success = state.uri.queryParameters['success'] == 'true';
          final message = state.uri.queryParameters['message'] ?? '';
          return NoTransitionPage(
            child: PaiementConfirmationPage(
              success: success,
              message: message,
            ),
          );
        },
      ),
      // Mentor
      GoRoute(
        path: '/mentor/dashboard',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: DashboardMentorPage()),
      ),
      // Admin
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: DashboardAdminPage()),
      ),
      // B2B
      GoRoute(
        path: '/b2b/dashboard',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: DashboardB2BPage()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFef4444), size: 48),
            const SizedBox(height: 16),
            Text(
              'Page introuvable',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? '404'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/vitrine'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
});
