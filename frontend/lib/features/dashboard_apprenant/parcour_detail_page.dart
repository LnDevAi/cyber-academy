import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/enrollments_api.dart';
import '../../core/api/courses_api.dart';
import '../../shared/models/enrollment.dart';
import '../../shared/models/cyber_range_session.dart';
import '../../shared/widgets/cyber_sidebar.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/lab_tile.dart';

final enrollmentDetailProvider =
    FutureProvider.autoDispose.family<Enrollment, String>((ref, id) async {
  final api = ref.read(enrollmentsApiProvider);
  try {
    final data = await api.getEnrollment(id);
    return Enrollment.fromJson(data);
  } catch (_) {
    return Enrollment(
      id: id,
      userId: '1',
      courseCode: 'C01-PEN',
      courseTitre: 'Pentest & Ethical Hacking',
      statut: 'actif',
      progression: 42,
      dateDebut: DateTime.now().subtract(const Duration(days: 14)),
      labsCompletes: 6,
      labsTotal: 15,
    );
  }
});

final labsForEnrollmentProvider =
    FutureProvider.autoDispose.family<List<Lab>, String>((ref, enrollmentId) async {
  try {
    final api = ref.read(coursesApiProvider);
    final data = await api.getLabs('C01-PEN'); // Use enrollment courseCode ideally
    return data.map((d) => Lab.fromJson(d as Map<String, dynamic>)).toList();
  } catch (_) {
    return List.generate(
        10,
        (i) => Lab(
              id: 'lab-$i',
              courseCode: 'C01-PEN',
              titre: [
                'Reconnaissance et OSINT',
                'Scanning réseau avec Nmap',
                'Exploitation Metasploit',
                'Injection SQL avancée',
                'XSS et CSRF',
                'Élévation de privilèges',
                'Pivoting et tunneling',
                'Exfiltration de données',
                'Couverture des traces',
                'Rapport de pentest',
              ][i],
              description: 'Lab pratique sur l\'environnement virtualisé Cyber Range.',
              ordre: i + 1,
              difficulte: (i % 5) + 1,
              dureeMinutes: 45 + (i % 4) * 15,
              statut: i < 6
                  ? 'termine'
                  : i == 6
                      ? 'en_cours'
                      : i == 7
                          ? 'disponible'
                          : 'verrouille',
            ));
  }
});

class ParcourDetailPage extends ConsumerStatefulWidget {
  final String enrollmentId;
  const ParcourDetailPage({super.key, required this.enrollmentId});

  @override
  ConsumerState<ParcourDetailPage> createState() => _ParcourDetailPageState();
}

class _ParcourDetailPageState extends ConsumerState<ParcourDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentAsync =
        ref.watch(enrollmentDetailProvider(widget.enrollmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          CyberSidebar(currentRoute: '/dashboard/parcours/${widget.enrollmentId}'),
          Expanded(
            child: enrollmentAsync.when(
              data: (enrollment) => _buildContent(enrollment),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Enrollment enrollment) {
    return Column(
      children: [
        // Header
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white54, size: 16),
                    label: Text('Tableau de bord',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment.courseCode,
                          style: GoogleFonts.inter(
                              color: AppColors.accentCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          enrollment.courseTitre ?? enrollment.courseCode,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressBar(
                          percent: enrollment.progression,
                          label: 'Progression globale',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  ProgressRing(percent: enrollment.progression, radius: 48),
                ],
              ),
            ],
          ),
        ),
        // Tabs
        Container(
          color: AppColors.cardWhite,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.accentCyan,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accentCyan,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Modules'),
              Tab(text: 'Labs'),
              Tab(text: 'Examen'),
              Tab(text: 'Ressources'),
              Tab(text: 'Mon mentor'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ModulesTab(enrollment: enrollment),
              _LabsTab(enrollment: enrollment),
              _ExamenTab(enrollment: enrollment),
              _RessourcesTab(),
              _MentorTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModulesTab extends StatefulWidget {
  final Enrollment enrollment;
  const _ModulesTab({required this.enrollment});

  @override
  State<_ModulesTab> createState() => _ModulesTabState();
}

class _ModulesTabState extends State<_ModulesTab> {
  int? _expanded;

  final _sampleModules = [
    {'titre': 'Module 1 — Introduction', 'complete': true, 'heures': 8},
    {'titre': 'Module 2 — Outils et environnement', 'complete': true, 'heures': 10},
    {'titre': 'Module 3 — Vulnérabilités web', 'complete': false, 'heures': 15},
    {'titre': 'Module 4 — Infrastructure', 'complete': false, 'heures': 12},
    {'titre': 'Module 5 — Examen et rapport', 'complete': false, 'heures': 8},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: _sampleModules.length,
      itemBuilder: (ctx, i) {
        final m = _sampleModules[i];
        final isComplete = m['complete'] as bool;
        final isExpanded = _expanded == i;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isComplete
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = isExpanded ? null : i),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isComplete
                              ? AppColors.success
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isComplete
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          isComplete ? Icons.check : null,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['titre'] as String,
                                style: GoogleFonts.inter(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('${m['heures']}h',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      if (isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Complété',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                        ),
                      Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(58, 0, 16, 16),
                  child: Column(
                    children: [
                      Text(
                        'Contenu du module — leçons théoriques et exercices pratiques sur le Cyber Range.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (!isComplete) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentCyan,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Commencer',
                                style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LabsTab extends ConsumerWidget {
  final Enrollment enrollment;
  const _LabsTab({required this.enrollment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labsAsync = ref.watch(labsForEnrollmentProvider(enrollment.id));

    return labsAsync.when(
      data: (labs) => ListView.builder(
        padding: const EdgeInsets.all(32),
        itemCount: labs.length,
        itemBuilder: (ctx, i) => LabTile(
          lab: labs[i],
          onLaunch: () => context.go(
              '/dashboard/parcours/${enrollment.id}/labs/${labs[i].id}'),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erreur de chargement des labs')),
    );
  }
}

class _ExamenTab extends StatelessWidget {
  final Enrollment enrollment;
  const _ExamenTab({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Examen de certification',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.quiz_outlined,
                        color: AppColors.accentCyan, size: 24),
                    const SizedBox(width: 12),
                    Text('Examen final',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                _ExamenInfo('Format', '80 questions QCM'),
                _ExamenInfo('Durée', '2 heures'),
                _ExamenInfo('Score minimal', '70%'),
                _ExamenInfo('Tentatives', '3 tentatives incluses'),
                const SizedBox(height: 20),
                Text(
                  'Condition: Complétez au moins 80% des modules avant de passer l\'examen.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                if (enrollment.progression < 80)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outlined,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Complétez ${80 - enrollment.progression.round()}% de plus pour débloquer l\'examen.',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.warning,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  CyberButton(
                    label: 'Passer l\'examen',
                    onPressed: () {},
                    icon: Icons.play_circle_outline,
                    width: 240,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamenInfo extends StatelessWidget {
  final String label;
  final String value;
  const _ExamenInfo(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RessourcesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ressources = [
      ('Fiche synthèse — Module 1', 'PDF', '245 Ko'),
      ('Fiche synthèse — Module 2', 'PDF', '380 Ko'),
      ('Glossaire cybersécurité UEMOA', 'PDF', '156 Ko'),
      ('Guide OWASP Top 10 (français)', 'PDF', '2.1 Mo'),
      ('Templates de rapport pentest', 'DOCX', '89 Ko'),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: ressources.length,
      itemBuilder: (ctx, i) {
        final r = ressources[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$1,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    Text('${r.$2} · ${r.$3}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 14),
                label: const Text('Télécharger'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  side: const BorderSide(color: AppColors.accentBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MentorTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mon mentor',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.cyberGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text('KS',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Koumba SALL',
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('Expert Pentest & Cybersécurité',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.accentCyan)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ...List.generate(
                                  5,
                                  (i) => const Icon(Icons.star,
                                      size: 14, color: AppColors.warning)),
                              const SizedBox(width: 6),
                              Text('5.0 · 48 sessions',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text('Planifier une session',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
