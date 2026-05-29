import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/mentor_api.dart';
import '../../shared/models/mentor_session.dart';
import '../../shared/widgets/cyber_sidebar.dart';
import '../../shared/widgets/progress_ring.dart';

final mentorApprenantsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final api = ref.read(mentorApiProvider);
    final data = await api.listMentorApprenants();
    return List<Map<String, dynamic>>.from(data);
  } catch (_) {
    return [
      {'nom': 'Issouf Traoré', 'course': 'C01-PEN', 'progression': 42, 'alert': false},
      {'nom': 'Aminata Coulibaly', 'course': 'B01-DPO', 'progression': 68, 'alert': false},
      {'nom': 'Moussa Ouédraogo', 'course': 'C02-CEH', 'progression': 18, 'alert': true},
      {'nom': 'Fatou Diallo', 'course': 'A01-CYB', 'progression': 85, 'alert': false},
      {'nom': 'Ibrahim Coulibaly', 'course': 'D01-NET', 'progression': 23, 'alert': true},
    ];
  }
});

final mentorSessionsProvider =
    FutureProvider.autoDispose<List<MentorSession>>((ref) async {
  try {
    final api = ref.read(mentorApiProvider);
    final data = await api.listMentorSessions();
    return data
        .map((d) => MentorSession.fromJson(d as Map<String, dynamic>))
        .toList();
  } catch (_) {
    final now = DateTime.now();
    return [
      MentorSession(
        id: '1',
        mentorId: 'mentor-1',
        apprenantId: 'user-1',
        enrollmentId: 'enroll-1',
        sujet: 'SQL Injection — Lab 4',
        dateHeure: now.add(const Duration(hours: 2)),
        dureeeMinutes: 60,
        statut: 'confirme',
        apprenantNom: 'Moussa Ouédraogo',
        visioUrl: 'https://meet.edefence.io/session/1',
      ),
      MentorSession(
        id: '2',
        mentorId: 'mentor-1',
        apprenantId: 'user-2',
        enrollmentId: 'enroll-2',
        sujet: 'Révision Module 3',
        dateHeure: now.add(const Duration(days: 1, hours: 3)),
        dureeeMinutes: 90,
        statut: 'planifie',
        apprenantNom: 'Ibrahim Coulibaly',
      ),
    ];
  }
});

final livrablesProvider =
    FutureProvider.autoDispose<List<Livrable>>((ref) async {
  try {
    final api = ref.read(mentorApiProvider);
    final data = await api.listLivrables();
    return data.map((d) => Livrable.fromJson(d as Map<String, dynamic>)).toList();
  } catch (_) {
    return [
      Livrable(
        id: '1',
        enrollmentId: 'enroll-1',
        apprenantNom: 'Issouf Traoré',
        titre: 'Rapport de pentest — Lab 2',
        moduleNom: 'Module 2 — Reconnaissance',
        dateDepot: DateTime.now().subtract(const Duration(days: 1)),
        statut: 'en_attente',
      ),
      Livrable(
        id: '2',
        enrollmentId: 'enroll-3',
        apprenantNom: 'Fatou Diallo',
        titre: 'Analyse de vulnérabilités',
        moduleNom: 'Module 3 — Exploitation',
        dateDepot: DateTime.now().subtract(const Duration(hours: 5)),
        statut: 'en_attente',
      ),
    ];
  }
});

class DashboardMentorPage extends ConsumerWidget {
  const DashboardMentorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apprenantsAsync = ref.watch(mentorApprenantsProvider);
    final sessionsAsync = ref.watch(mentorSessionsProvider);
    final livrablesAsync = ref.watch(livrablesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const CyberSidebar(currentRoute: '/mentor/dashboard'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tableau de bord Mentor',
                              style: GoogleFonts.inter(
                                  fontSize: 24, fontWeight: FontWeight.w800)),
                          Text(
                            DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                                .format(DateTime.now()),
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Apprenants section
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('Mes apprenants', Icons.people_outlined),
                            const SizedBox(height: 16),
                            apprenantsAsync.when(
                              data: (apprenants) => Column(
                                children: apprenants
                                    .map((a) => _ApprenantRow(data: a))
                                    .toList(),
                              ),
                              loading: () =>
                                  const Center(child: CircularProgressIndicator()),
                              error: (_, __) =>
                                  const Text('Erreur de chargement'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sessions
                            _SectionTitle(
                                'Sessions à venir', Icons.calendar_month_outlined),
                            const SizedBox(height: 16),
                            sessionsAsync.when(
                              data: (sessions) => sessions.isEmpty
                                  ? _EmptyState('Aucune session planifiée')
                                  : Column(
                                      children: sessions
                                          .map((s) => _SessionCard(session: s))
                                          .toList(),
                                    ),
                              loading: () =>
                                  const Center(child: CircularProgressIndicator()),
                              error: (_, __) =>
                                  const Text('Erreur de chargement'),
                            ),
                            const SizedBox(height: 32),
                            // Livrables
                            _SectionTitle(
                                'Livrables à corriger', Icons.assignment_outlined),
                            const SizedBox(height: 16),
                            livrablesAsync.when(
                              data: (livrables) => livrables.isEmpty
                                  ? _EmptyState('Aucun livrable en attente')
                                  : Column(
                                      children: livrables
                                          .map((l) => _LivrableCard(
                                                livrable: l,
                                                onCorrect: () {
                                                  _showCorrectionDialog(context, l);
                                                },
                                              ))
                                          .toList(),
                                    ),
                              loading: () =>
                                  const Center(child: CircularProgressIndicator()),
                              error: (_, __) =>
                                  const Text('Erreur de chargement'),
                            ),
                          ],
                        ),
                      ),
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

  void _showCorrectionDialog(BuildContext context, Livrable livrable) {
    final noteCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    int note = 15;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Corriger: ${livrable.titre}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apprenant: ${livrable.apprenantNom}',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                Text('Note /20',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Slider(
                  value: note.toDouble(),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  label: '$note/20',
                  activeColor: AppColors.accentCyan,
                  onChanged: (v) => setDialogState(() => note = v.round()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Commentaire',
                    hintText: 'Feedback pour l\'apprenant...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Note $note/20 enregistrée pour ${livrable.apprenantNom}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan, elevation: 0),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accentCyan),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ApprenantRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ApprenantRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final progression = (data['progression'] as num).toDouble();
    final isAlert = data['alert'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAlert ? AppColors.warning.withOpacity(0.5) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.cyberGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                (data['nom'] as String).split(' ').map((p) => p[0]).take(2).join(),
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data['nom'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    if (isAlert) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('En difficulté',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text(data['course'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: LinearProgressBar(percent: progression),
          ),
          const SizedBox(width: 8),
          Text('${progression.round()}%',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: progression < 30
                      ? AppColors.danger
                      : progression < 70
                          ? AppColors.warning
                          : AppColors.accentCyan)),
          const SizedBox(width: 12),
          if (isAlert)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('Contacter',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final MentorSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM · HH:mm', 'fr_FR');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outlined, size: 14, color: AppColors.accentCyan),
              const SizedBox(width: 6),
              Text(session.apprenantNom ?? 'Apprenant',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(session.sujet,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(dateFormat.format(session.dateHeure),
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              const Spacer(),
              if (session.visioUrl != null)
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentCyan,
                    side: const BorderSide(color: AppColors.accentCyan),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    textStyle: GoogleFonts.inter(fontSize: 11),
                  ),
                  child: const Text('Rejoindre'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LivrableCard extends StatelessWidget {
  final Livrable livrable;
  final VoidCallback onCorrect;
  const _LivrableCard({required this.livrable, required this.onCorrect});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm', 'fr_FR');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(livrable.titre,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${livrable.apprenantNom} · ${livrable.moduleNom}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(dateFormat.format(livrable.dateDepot),
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              const Spacer(),
              ElevatedButton(
                onPressed: onCorrect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: Text('Corriger',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(message,
          style: GoogleFonts.inter(
              color: AppColors.textMuted, fontSize: 13),
          textAlign: TextAlign.center),
    );
  }
}
