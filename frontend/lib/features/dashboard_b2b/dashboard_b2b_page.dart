import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_stats.dart';
import '../../shared/widgets/cyber_sidebar.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/stat_card.dart';

final b2bCompanyProvider = FutureProvider.autoDispose<B2BCompany>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return B2BCompany(
    id: 'company-1',
    nomEntreprise: 'SGBF — Société Générale Burkina Faso',
    secteur: 'Banque & Finance',
    planAbonnement: 'Entreprise',
    seatsTotal: 30,
    seatsUtilises: 18,
    dateDebut: DateTime(2026, 1, 1),
    dateFin: DateTime(2026, 12, 31),
    montantContrat: 2250000,
    employes: List.generate(
      18,
      (i) => B2BEmployee(
        id: 'emp-$i',
        nomComplet: [
          'Issouf Traoré', 'Aminata Coulibaly', 'Moussa Ouédraogo',
          'Fatou Diallo', 'Ibrahim Coulibaly', 'Mariam Sawadogo',
          'Ali Kaboré', 'Assita Zongo', 'Hamidou Ouédraogo',
        ][i % 9],
        email: 'emp${i + 1}@sgbf.bf',
        courseCode: ['C01-PEN', 'B01-DPO', 'A01-CYB', 'D01-NET', 'E01-FOR'][i % 5],
        courseTitre: ['Pentest & Ethical Hacking', 'DPO', 'Fondamentaux Cyber', 'Sécurité Réseaux', 'Forensic'][i % 5],
        progression: (i * 7 + 15) % 100.0,
        badgesObtenus: i % 3,
        derniereConnexion: DateTime.now().subtract(Duration(hours: i * 5)),
      ),
    ),
  );
});

final b2bFacturesProvider = FutureProvider.autoDispose<List<Facture>>((ref) async {
  return [
    Facture(
      id: 'FAC-2026-001',
      companyId: 'company-1',
      montant: 2250000,
      statut: 'payee',
      dateEmission: DateTime(2026, 1, 1),
      datePaiement: DateTime(2026, 1, 5),
    ),
    Facture(
      id: 'FAC-2026-002',
      companyId: 'company-1',
      montant: 375000,
      statut: 'en_attente',
      dateEmission: DateTime(2026, 5, 1),
    ),
  ];
});

class DashboardB2BPage extends ConsumerStatefulWidget {
  const DashboardB2BPage({super.key});

  @override
  ConsumerState<DashboardB2BPage> createState() => _DashboardB2BPageState();
}

class _DashboardB2BPageState extends ConsumerState<DashboardB2BPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(b2bCompanyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const CyberSidebar(currentRoute: '/b2b/dashboard'),
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: AppColors.primaryDark,
                  child: companyAsync.when(
                    data: (company) => Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(company.nomEntreprise,
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                            Text(
                              '${company.secteur} · Plan ${company.planAbonnement}',
                              style: GoogleFonts.inter(
                                  color: AppColors.accentCyan, fontSize: 12),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Seats counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${company.seatsUtilises}/${company.seatsTotal}',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800),
                              ),
                              Text('Sièges utilisés',
                                  style: GoogleFonts.inter(
                                      color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showInscriptionDialog(context, company),
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Inscrire des collaborateurs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentCyan,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(height: 40),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                // Tab bar
                Container(
                  color: AppColors.cardWhite,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.accentCyan,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.accentCyan,
                    labelStyle:
                        GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Mon équipe'),
                      Tab(text: 'Progression'),
                      Tab(text: 'Facturation'),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: companyAsync.when(
                    data: (company) => TabBarView(
                      controller: _tabController,
                      children: [
                        _EquipeTab(company: company),
                        _ProgressionTab(company: company),
                        _FacturationTab(),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Erreur de chargement')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInscriptionDialog(BuildContext context, B2BCompany company) {
    final disponibles = company.seatsDisponibles;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Inscrire des collaborateurs',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
                ),
                child: Text(
                  '$disponibles siège${disponibles > 1 ? 's' : ''} disponible${disponibles > 1 ? 's' : ''} sur ${company.seatsTotal}',
                  style: GoogleFonts.inter(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Emails des collaborateurs (séparés par virgule)',
                  hintText: 'email1@entreprise.com, email2@entreprise.com',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Formation à attribuer',
                  hintText: 'Sélectionner...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invitations envoyées avec succès'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan, elevation: 0),
            child: const Text('Envoyer les invitations'),
          ),
        ],
      ),
    );
  }
}

class _EquipeTab extends StatelessWidget {
  final B2BCompany company;
  const _EquipeTab({required this.company});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm', 'fr_FR');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${company.employes.length} collaborateurs inscrits',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Exporter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  side: const BorderSide(color: AppColors.accentBlue),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.inter(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...company.employes.map((emp) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          emp.nomComplet.split(' ').map((p) => p[0]).take(2).join(),
                          style: GoogleFonts.inter(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.nomComplet,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(emp.email,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.courseTitre ?? emp.courseCode ?? 'N/A',
                              style: GoogleFonts.inter(fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          LinearProgressBar(percent: emp.progression),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${emp.progression.round()}%',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text('${emp.badgesObtenus}',
                            style: GoogleFonts.inter(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    if (emp.derniereConnexion != null)
                      Text(
                        dateFormat.format(emp.derniereConnexion!),
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ProgressionTab extends StatelessWidget {
  final B2BCompany company;
  const _ProgressionTab({required this.company});

  @override
  Widget build(BuildContext context) {
    final avgProgress = company.employes.isEmpty
        ? 0.0
        : company.employes.fold<double>(0, (s, e) => s + e.progression) /
            company.employes.length;
    final completed = company.employes.where((e) => e.progression >= 100).length;
    final badges =
        company.employes.fold<int>(0, (s, e) => s + e.badgesObtenus);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up,
                  value: '${avgProgress.round()}%',
                  label: 'Progression moyenne',
                  iconColor: AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  icon: Icons.check_circle_outlined,
                  value: '$completed',
                  label: 'Formations complétées',
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  icon: Icons.workspace_premium_outlined,
                  value: '$badges',
                  label: 'Badges obtenus',
                  iconColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  icon: Icons.people,
                  value: '${company.seatsUtilises}/${company.seatsTotal}',
                  label: 'Sièges utilisés',
                  iconColor: AppColors.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Progress visualization
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
                Text('Progression par collaborateur',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                ...company.employes.take(8).map((emp) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(
                              emp.nomComplet.split(' ').first,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: LinearProgressBar(percent: emp.progression),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${emp.progression.round()}%',
                              style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FacturationTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facturesAsync = ref.watch(b2bFacturesProvider);
    final formatter = NumberFormat('#,###', 'fr_FR');
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return facturesAsync.when(
      data: (factures) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historique de facturation',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            ...factures.map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: f.statut == 'payee'
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          f.statut == 'payee'
                              ? Icons.receipt
                              : Icons.receipt_long,
                          color: f.statut == 'payee'
                              ? AppColors.success
                              : AppColors.warning,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.id,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(
                              'Émise le ${dateFormat.format(f.dateEmission)}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${formatter.format(f.montant)} FCFA',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: f.statut == 'payee'
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          f.statut == 'payee' ? 'Payée' : 'En attente',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: f.statut == 'payee'
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined, size: 14),
                        label: const Text('PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentBlue,
                          side: const BorderSide(color: AppColors.accentBlue),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          textStyle: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erreur de chargement')),
    );
  }
}
