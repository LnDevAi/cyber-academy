import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/enrollments_api.dart';
import '../../core/api/badges_api.dart';
import '../../features/auth/auth_provider.dart';
import '../../shared/models/enrollment.dart';
import '../../shared/models/badge.dart' as model;
import '../../shared/models/course.dart';
import '../../shared/widgets/cyber_sidebar.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/progress_ring.dart';

final enrollmentsProvider = FutureProvider.autoDispose<List<Enrollment>>((ref) async {
  final api = ref.read(enrollmentsApiProvider);
  try {
    final data = await api.listEnrollments();
    return data.map((d) => Enrollment.fromJson(d as Map<String, dynamic>)).toList();
  } catch (_) {
    // Return sample data
    return [
      Enrollment(
        id: '1',
        userId: '1',
        courseCode: 'C01-PEN',
        courseTitre: 'Pentest & Ethical Hacking',
        statut: 'actif',
        progression: 42,
        dateDebut: DateTime.now().subtract(const Duration(days: 14)),
        labsCompletes: 6,
        labsTotal: 15,
      ),
      Enrollment(
        id: '2',
        userId: '1',
        courseCode: 'A01-CYB',
        courseTitre: 'Fondamentaux de la Cybersécurité',
        statut: 'termine',
        progression: 100,
        dateDebut: DateTime.now().subtract(const Duration(days: 60)),
        dateFin: DateTime.now().subtract(const Duration(days: 5)),
        labsCompletes: 5,
        labsTotal: 5,
      ),
    ];
  }
});

final badgesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final api = ref.read(badgesApiProvider);
  try {
    final data = await api.listBadges();
    return data.length;
  } catch (_) {
    return 2;
  }
});

class DashboardApprenantPage extends ConsumerWidget {
  const DashboardApprenantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final enrollmentsAsync = ref.watch(enrollmentsProvider);
    final badgesAsync = ref.watch(badgesCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          CyberSidebar(currentRoute: '/dashboard'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour ${user?.prenom ?? 'Apprenant'} 👋',
                            style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/catalogue'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Nouveau parcours'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentCyan,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Stats row
                  enrollmentsAsync.when(
                    data: (enrollments) {
                      final actifs = enrollments.where((e) => e.isActif).length;
                      final labs = enrollments.fold<int>(0, (s, e) => s + e.labsCompletes);

                      return Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.school_outlined,
                              value: '$actifs',
                              label: 'Parcours en cours',
                              iconColor: AppColors.accentBlue,
                              trend: actifs > 0 ? 'Actif' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              icon: Icons.terminal,
                              value: '$labs',
                              label: 'Labs complétés',
                              iconColor: AppColors.accentCyan,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: badgesAsync.when(
                              data: (count) => StatCard(
                                icon: Icons.workspace_premium,
                                value: '$count',
                                label: 'Badges obtenus',
                                iconColor: AppColors.warning,
                                trend: '+1 ce mois',
                              ),
                              loading: () => const StatCard(
                                icon: Icons.workspace_premium,
                                value: '...',
                                label: 'Badges obtenus',
                                iconColor: AppColors.warning,
                              ),
                              error: (_, __) => const StatCard(
                                icon: Icons.workspace_premium,
                                value: '0',
                                label: 'Badges obtenus',
                                iconColor: AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              icon: Icons.timer_outlined,
                              value: '${enrollments.fold<int>(0, (s, e) => s + (e.course?.dureeHeures ?? 0))}h',
                              label: 'Heures de pratique',
                              iconColor: AppColors.success,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),
                  // Enrollments section
                  Row(
                    children: [
                      Text('Mes parcours en cours',
                          style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/catalogue'),
                        child: const Text('+ Ajouter un parcours'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  enrollmentsAsync.when(
                    data: (enrollments) {
                      if (enrollments.isEmpty) {
                        return _EmptyEnrollments();
                      }
                      return Column(
                        children: enrollments
                            .map((e) => _EnrollmentCard(enrollment: e))
                            .toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Erreur de chargement'),
                  ),
                  const SizedBox(height: 32),
                  // Quick access widgets row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TARGUI quick access
                      Expanded(
                        child: _QuickWidget(
                          title: 'TARGUI IA',
                          subtitle: 'Posez vos questions à votre tuteur IA',
                          icon: Icons.smart_toy_outlined,
                          color: AppColors.accentCyan,
                          onTap: () => context.go('/dashboard/targui'),
                          action: 'Ouvrir TARGUI',
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Badges quick access
                      Expanded(
                        child: _QuickWidget(
                          title: 'Mes badges',
                          subtitle: 'Vos certifications blockchain E-DEFENCE',
                          icon: Icons.workspace_premium_outlined,
                          color: AppColors.warning,
                          onTap: () => context.go('/dashboard/badges'),
                          action: 'Voir mes badges',
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Upcoming session
                      const Expanded(child: _UpcomingSessionWidget()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  final Enrollment enrollment;

  const _EnrollmentCard({required this.enrollment});

  Color _blocColor(String code) {
    final bloc = code.isNotEmpty ? code[0] : 'A';
    switch (bloc) {
      case 'A': return AppColors.blocA;
      case 'B': return AppColors.blocB;
      case 'C': return AppColors.blocC;
      case 'D': return AppColors.blocD;
      case 'E': return AppColors.blocE;
      default: return AppColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _blocColor(enrollment.courseCode);
    final isTermine = enrollment.isTermine;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Progress ring
          ProgressRing(percent: enrollment.progression, radius: 34, lineWidth: 6),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      enrollment.courseCode,
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700, color: color),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isTermine
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.accentCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isTermine ? 'Terminé' : 'En cours',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isTermine ? AppColors.success : AppColors.accentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  enrollment.courseTitre ?? enrollment.courseCode,
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '${enrollment.labsCompletes}/${enrollment.labsTotal} labs · ${enrollment.progression.round()}% complété',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => context
                    .go('/dashboard/parcours/${enrollment.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isTermine ? 'Voir le détail' : 'Continuer',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (!isTermine) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      context.go('/dashboard/parcours/${enrollment.id}/labs'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentCyan,
                    side: const BorderSide(color: AppColors.accentCyan),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Cyber Range',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyEnrollments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Aucun parcours en cours',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez votre premier parcours en cybersécurité',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          CyberButton(
            label: 'Explorer le catalogue',
            onPressed: () => context.go('/catalogue'),
            icon: Icons.explore,
          ),
        ],
      ),
    );
  }
}

class _QuickWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String action;

  const _QuickWidget({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 14),
            Text(
              action,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingSessionWidget extends StatelessWidget {
  const _UpcomingSessionWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: AppColors.accentBlue, size: 22),
          ),
          const SizedBox(height: 14),
          Text('Session mentor',
              style:
                  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Prochaine session avec votre mentor',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, size: 14, color: AppColors.accentBlue),
                const SizedBox(width: 8),
                Text(
                  'Pas de session planifiée',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
