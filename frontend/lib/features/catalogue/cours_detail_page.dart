import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/courses_api.dart';
import '../../shared/models/course.dart';
import 'catalogue_page.dart';

final courseDetailProvider =
    FutureProvider.autoDispose.family<Course, String>((ref, code) async {
  final api = ref.read(coursesApiProvider);
  try {
    final data = await api.getCourseDetail(code);
    return Course.fromJson(data);
  } catch (_) {
    final sample = CourseData.sampleCourses.firstWhere(
      (c) => c['code'] == code,
      orElse: () => CourseData.sampleCourses.first,
    );
    return Course.fromJson(sample);
  }
});

class CoursDetailPage extends ConsumerWidget {
  final String courseCode;
  const CoursDetailPage({super.key, required this.courseCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseCode));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: courseAsync.when(
        data: (course) => _CoursDetailContent(course: course),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              Text('Formation introuvable',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/catalogue'),
                child: const Text('Retour au catalogue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoursDetailContent extends ConsumerWidget {
  final Course course;
  const _CoursDetailContent({required this.course});

  Color get blocColor {
    switch (course.bloc) {
      case 'A': return AppColors.blocA;
      case 'B': return AppColors.blocB;
      case 'C': return AppColors.blocC;
      case 'D': return AppColors.blocD;
      case 'E': return AppColors.blocE;
      default: return AppColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat('#,###', 'fr_FR');

    return Column(
      children: [
        // Header
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.fromLTRB(48, 16, 48, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/catalogue'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 16),
                    label: Text('Catalogue',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                  ),
                  Text(' / ', style: GoogleFonts.inter(color: Colors.white38)),
                  Text(
                    course.code,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: blocColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('BLOC ${course.bloc} — ${course.blocLabel}',
                                  style: GoogleFonts.inter(
                                      color: blocColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (course.isEDefence
                                        ? AppColors.accentCyan
                                        : AppColors.warning)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(course.typeLabel,
                                  style: GoogleFonts.inter(
                                      color: course.isEDefence
                                          ? AppColors.accentCyan
                                          : AppColors.warning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          course.titre,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          course.description,
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 15, height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          children: [
                            _InfoBadge(Icons.schedule, '${course.dureeHeures}h de contenu'),
                            _InfoBadge(Icons.terminal, '${course.nombreLabs} labs pratiques'),
                            _InfoBadge(Icons.verified,
                                course.partenaire),
                            _InfoBadge(Icons.bar_chart, _niveauLabel(course.niveau)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  // Price card
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatter.format(course.prix)} FCFA',
                          style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                        if (course.paiementEchelonne) ...[
                          const SizedBox(height: 4),
                          Text(
                            'ou 3× ${formatter.format((course.prix / 3).round())} FCFA',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.success),
                          ),
                        ],
                        const SizedBox(height: 20),
                        CyberButton(
                          label: "S'inscrire maintenant",
                          onPressed: () => context.go('/register'),
                          width: double.infinity,
                          icon: Icons.rocket_launch_outlined,
                        ),
                        const SizedBox(height: 12),
                        if (course.isInternational)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.warning.withOpacity(0.2)),
                            ),
                            child: Text(
                              'Note: L\'examen de certification est passé directement auprès de ${course.partenaire}. Nous préparons et accompagnons.',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.warning, height: 1.4),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text('Paiement sécurisé CinetPay / Stripe',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Body tabs
        Expanded(
          child: _CoursDetailTabs(course: course),
        ),
      ],
    );
  }

  String _niveauLabel(String n) {
    switch (n) {
      case 'debutant': return 'Débutant';
      case 'intermediaire': return 'Intermédiaire';
      case 'avance': return 'Avancé';
      default: return n;
    }
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoBadge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _CoursDetailTabs extends StatefulWidget {
  final Course course;
  const _CoursDetailTabs({required this.course});

  @override
  State<_CoursDetailTabs> createState() => _CoursDetailTabsState();
}

class _CoursDetailTabsState extends State<_CoursDetailTabs>
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
    return Column(
      children: [
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
              Tab(text: 'Programme'),
              Tab(text: 'Prérequis & Public'),
              Tab(text: 'Labs inclus'),
              Tab(text: 'Examen'),
              Tab(text: 'Instructeur'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ProgrammeTab(course: widget.course),
              _PrerequisPublicTab(course: widget.course),
              _LabsTab(course: widget.course),
              _ExamenTab(course: widget.course),
              _InstructeurTab(course: widget.course),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgrammeTab extends StatefulWidget {
  final Course course;
  const _ProgrammeTab({required this.course});

  @override
  State<_ProgrammeTab> createState() => _ProgrammeTabState();
}

class _ProgrammeTabState extends State<_ProgrammeTab> {
  int? _expandedModule;

  // Sample modules if none returned
  List<Map<String, dynamic>> get _sampleModules {
    return [
      {
        'titre': 'Module 1 — Introduction et fondamentaux',
        'desc': 'Concepts de base, terminologie, cadre légal et réglementaire applicable en Afrique de l\'Ouest.',
        'heures': 8,
        'sousModules': ['1.1 Histoire de la cybersécurité', '1.2 Menaces et vecteurs d\'attaque', '1.3 Cadre légal UEMOA'],
      },
      {
        'titre': 'Module 2 — Technologies et outils',
        'desc': 'Prise en main des outils professionnels. Premiers labs sur le Cyber Range.',
        'heures': 12,
        'sousModules': ['2.1 Kali Linux & outils', '2.2 Premiers labs pratiques', '2.3 Méthodologie'],
      },
      {
        'titre': 'Module 3 — Attaques et vulnérabilités',
        'desc': 'Classification des vulnérabilités OWASP Top 10, exploitation, rapport.',
        'heures': 15,
        'sousModules': ['3.1 OWASP Top 10', '3.2 SQLi et XSS', '3.3 Labs d\'exploitation'],
      },
      {
        'titre': 'Module 4 — Défense et réponse',
        'desc': 'Durcissement systèmes, monitoring, SIEM, gestion des incidents.',
        'heures': 10,
        'sousModules': ['4.1 Hardening', '4.2 SIEM et logs', '4.3 Réponse aux incidents'],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final modules = widget.course.modules.isNotEmpty
        ? widget.course.modules.map((m) => {
              'titre': m.titre,
              'desc': m.description,
              'heures': m.dureeHeures,
              'sousModules': m.sousModules,
            }).toList()
        : _sampleModules;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Programme détaillé',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.course.dureeHeures} heures au total · ${modules.length} modules',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ...modules.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final isExpanded = _expandedModule == i;
            final sousModules = m['sousModules'] as List? ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isExpanded
                        ? AppColors.accentCyan.withOpacity(0.3)
                        : AppColors.border),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(
                        () => _expandedModule = isExpanded ? null : i),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: GoogleFonts.inter(
                                      color: AppColors.accentCyan,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['titre'] as String,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${m['heures']}h · ${sousModules.length} leçons',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Container(
                      padding: const EdgeInsets.fromLTRB(62, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['desc'] as String,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5)),
                          const SizedBox(height: 12),
                          ...sousModules.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.play_circle_outline,
                                        size: 14, color: AppColors.accentCyan),
                                    const SizedBox(width: 8),
                                    Text(s.toString(),
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PrerequisPublicTab extends StatelessWidget {
  final Course course;
  const _PrerequisPublicTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final prereqs = course.prerequis.isNotEmpty
        ? course.prerequis
        : ['Notions de base en informatique', 'Accès à un navigateur web', 'Connexion internet (3G suffisant)'];
    final publics = course.publicCible.isNotEmpty
        ? course.publicCible
        : ['Étudiants en informatique', 'Administrateurs systèmes', 'DPO et juristes', 'Décideurs et managers IT', 'Grand public motivé'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ListSection(
              title: 'Prérequis',
              icon: Icons.checklist,
              color: AppColors.warning,
              items: prereqs,
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: _ListSection(
              title: 'Public cible',
              icon: Icons.people_outlined,
              color: AppColors.accentCyan,
              items: publics,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  const _ListSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 20),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.check, size: 13, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _LabsTab extends StatelessWidget {
  final Course course;
  const _LabsTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final labs = List.generate(course.nombreLabs, (i) {
      final titles = [
        'Reconnaissance et OSINT',
        'Scanning réseau (Nmap)',
        'Exploitation de services',
        'Injection SQL',
        'Cross-Site Scripting (XSS)',
        'Élévation de privilèges Linux',
        'Crack de mots de passe',
        'Sniffing réseau',
        'Attaques Web OWASP',
        'Post-exploitation',
        'Forensic disque',
        'Analyse de malware',
        'Buffer Overflow',
        'Social Engineering',
        'Rapport de pentest',
      ];
      return {
        'num': i + 1,
        'titre': i < titles.length ? titles[i] : 'Lab pratique ${i + 1}',
        'duree': 45 + (i % 4) * 15,
        'difficulte': (i % 5) + 1,
      };
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Labs inclus — ${course.nombreLabs} lab${course.nombreLabs > 1 ? 's' : ''}',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Environnements virtualisés via Cyber Range (k3s + Guacamole). Accessible directement dans votre navigateur.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ...labs.map((lab) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('${lab['num']}',
                            style: GoogleFonts.inter(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(lab['titre'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < (lab['difficulte'] as int)
                                    ? Icons.star
                                    : Icons.star_outline,
                                size: 13,
                                color: i < (lab['difficulte'] as int)
                                    ? AppColors.warning
                                    : AppColors.textMuted,
                              )),
                    ),
                    const SizedBox(width: 12),
                    Text('${lab['duree']} min',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.lock_outlined,
                        size: 14, color: AppColors.textMuted),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ExamenTab extends StatelessWidget {
  final Course course;
  const _ExamenTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final format = course.formatExamen.isNotEmpty
        ? course.formatExamen
        : course.isEDefence
            ? 'Examen en ligne sur la plateforme E-DEFENCE. 80 questions QCM. Durée: 2h. Score minimal: 70%. Résultats immédiats.'
            : 'Examen administré par ${course.partenaire}. Inscription séparée auprès du partenaire. Nous vous préparons et accompagnons pour maximiser vos chances.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Format d\'examen',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
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
                      Icon(
                        course.isEDefence
                            ? Icons.computer_outlined
                            : Icons.business_outlined,
                        color: AppColors.accentCyan,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        course.isEDefence
                            ? 'Examen E-DEFENCE (en ligne)'
                            : 'Examen ${course.partenaire}',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(format,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                  const SizedBox(height: 20),
                  if (!course.isEDefence)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.warning.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outlined,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Frais d\'examen non inclus dans le prix de la formation. Nous vous accompagnons dans l\'inscription auprès de ${course.partenaire}.',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.warning, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructeurTab extends StatelessWidget {
  final Course course;
  const _InstructeurTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final nom = course.instructeurNom.isNotEmpty
        ? course.instructeurNom
        : 'Dr. Amadou SAWADOGO';
    final bio = course.instructeurBio.isNotEmpty
        ? course.instructeurBio
        : 'Expert en cybersécurité avec 12 ans d\'expérience. Certifié CISSP, CEH, CISM. Formateur accrédité PECB et EC-Council. Ancien RSSI d\'une institution financière panafricaine. Spécialiste des contextes UEMOA et OHADA.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre instructeur',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.cyberGradient,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Center(
                      child: Text(
                        nom.split(' ').map((p) => p[0]).take(2).join(),
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nom,
                            style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Expert Cybersécurité — E-DEFENCE Academy',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.accentCyan)),
                        const SizedBox(height: 12),
                        Text(bio,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.6)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
