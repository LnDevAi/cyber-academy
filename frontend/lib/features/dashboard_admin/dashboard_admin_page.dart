import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_stats.dart';
import '../../shared/widgets/cyber_sidebar.dart';
import '../../shared/widgets/stat_card.dart';

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return AdminStats.sample;
});

// Sample data
final _sampleUsers = List.generate(
  20,
  (i) => {
    'id': i + 1,
    'nom': [
      'Issouf Traoré', 'Aminata Coulibaly', 'Moussa Ouédraogo',
      'Fatou Diallo', 'Ibrahim Coulibaly', 'Mariam Sawadogo',
      'Ali Kaboré', 'Assita Zongo', 'Hamidou Ouédraogo', 'Aïcha Diallo',
    ][i % 10],
    'email': 'user${i + 1}@example.com',
    'profil': ['Étudiant', 'Pentester', 'DPO', 'Admin système', 'Décideur'][i % 5],
    'role': i < 2 ? 'admin' : i < 5 ? 'mentor' : 'apprenant',
    'inscription': DateTime.now().subtract(Duration(days: i * 3)),
    'parcours': (i % 4) + 0,
  },
);

final _samplePayments = List.generate(
  15,
  (i) => {
    'id': 'PAY-${1000 + i}',
    'apprenant': 'Apprenant ${i + 1}',
    'cours': ['C01-PEN', 'A01-CYB', 'B01-DPO', 'D01-NET', 'E01-FOR'][i % 5],
    'montant': [75000, 120000, 150000, 130000, 140000][i % 5],
    'methode': ['orange_money', 'moov_money', 'wave', 'stripe'][i % 4],
    'statut': i < 10 ? 'confirme' : i < 13 ? 'en_attente' : 'echoue',
    'date': DateTime.now().subtract(Duration(days: i)),
  },
);

class DashboardAdminPage extends ConsumerStatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  ConsumerState<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends ConsumerState<DashboardAdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _userSearch = '';
  final _userSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const CyberSidebar(currentRoute: '/admin/dashboard'),
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: AppColors.primaryDark,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Administration — Cyber Academy',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          Text('Back-office E-DEFENCE',
                              style: GoogleFonts.inter(
                                  color: AppColors.accentCyan, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                    color: AppColors.success, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Système opérationnel',
                                style: GoogleFonts.inter(
                                    color: AppColors.accentCyan, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab bar
                Container(
                  color: AppColors.cardWhite,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.accentCyan,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.accentCyan,
                    labelStyle:
                        GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Aperçu'),
                      Tab(text: 'Utilisateurs'),
                      Tab(text: 'Paiements'),
                      Tab(text: 'Catalogue'),
                      Tab(text: 'Badges'),
                      Tab(text: 'Conformité'),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ApercuTab(statsAsync: statsAsync),
                      _UtilisateursTab(search: _userSearch, searchCtrl: _userSearchCtrl, onSearch: (v) => setState(() => _userSearch = v)),
                      _PaiementsTab(),
                      _CatalogueTab(),
                      _BadgesAdminTab(),
                      _ConformiteTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApercuTab extends StatelessWidget {
  final AsyncValue<AdminStats> statsAsync;
  const _ApercuTab({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      data: (stats) {
        final formatter = NumberFormat('#,###', 'fr_FR');
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // KPI row 1
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.person_add_outlined,
                      value: '${stats.inscriptionsAujourdhui}',
                      label: "Inscriptions aujourd'hui",
                      iconColor: AppColors.accentCyan,
                      trend: '+${stats.inscriptionsSemaine} ce mois',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.payment,
                      value: '${formatter.format(stats.revenusMois)} FCFA',
                      label: 'Revenus ce mois',
                      iconColor: AppColors.success,
                      trend: '↑ 12%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.terminal,
                      value: '${stats.sessionsRangeActives}',
                      label: 'Sessions Range actives',
                      iconColor: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.trending_up,
                      value: '${stats.tauxCompletion.round()}%',
                      label: 'Taux de complétion',
                      iconColor: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.people,
                      value: '${stats.utilisateursTotal}',
                      label: 'Utilisateurs total',
                      iconColor: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.school,
                      value: '${stats.inscriptionsMois}',
                      label: 'Inscriptions ce mois',
                      iconColor: AppColors.blocE,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.workspace_premium,
                      value: '${stats.badgesEmis}',
                      label: 'Badges émis total',
                      iconColor: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.menu_book,
                      value: '${stats.coursTotal}',
                      label: 'Cours au catalogue',
                      iconColor: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erreur de chargement')),
    );
  }
}

class _UtilisateursTab extends StatelessWidget {
  final String search;
  final TextEditingController searchCtrl;
  final Function(String) onSearch;

  const _UtilisateursTab({
    required this.search,
    required this.searchCtrl,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = _sampleUsers
        .where((u) =>
            search.isEmpty ||
            (u['nom'] as String).toLowerCase().contains(search.toLowerCase()) ||
            (u['email'] as String).toLowerCase().contains(search.toLowerCase()))
        .toList();
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: searchCtrl,
                  onChanged: onSearch,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un utilisateur...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Créer un utilisateur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 16,
            headingTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textSecondary),
            dataTextStyle: GoogleFonts.inter(fontSize: 13),
            columns: const [
              DataColumn2(label: Text('Nom'), size: ColumnSize.L),
              DataColumn2(label: Text('Email'), size: ColumnSize.L),
              DataColumn2(label: Text('Profil'), size: ColumnSize.M),
              DataColumn2(label: Text('Rôle'), size: ColumnSize.S),
              DataColumn2(label: Text('Inscription'), size: ColumnSize.M),
              DataColumn2(label: Text('Actions'), size: ColumnSize.S),
            ],
            rows: filtered.map((u) {
              final role = u['role'] as String;
              return DataRow2(
                cells: [
                  DataCell(Text(u['nom'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(u['email'] as String)),
                  DataCell(Text(u['profil'] as String)),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: role == 'admin'
                          ? AppColors.danger.withOpacity(0.1)
                          : role == 'mentor'
                              ? AppColors.warning.withOpacity(0.1)
                              : AppColors.accentCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: role == 'admin'
                            ? AppColors.danger
                            : role == 'mentor'
                                ? AppColors.warning
                                : AppColors.accentCyan,
                      ),
                    ),
                  )),
                  DataCell(Text(dateFormat.format(u['inscription'] as DateTime))),
                  DataCell(Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        color: AppColors.accentBlue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.delete_outline, size: 16),
                        color: AppColors.danger,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PaiementsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('${_samplePayments.length} paiements',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exporter CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  side: const BorderSide(color: AppColors.accentBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 16,
            headingTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textSecondary),
            dataTextStyle: GoogleFonts.inter(fontSize: 13),
            columns: const [
              DataColumn2(label: Text('ID'), size: ColumnSize.S),
              DataColumn2(label: Text('Apprenant'), size: ColumnSize.M),
              DataColumn2(label: Text('Cours'), size: ColumnSize.S),
              DataColumn2(label: Text('Montant'), size: ColumnSize.M),
              DataColumn2(label: Text('Méthode'), size: ColumnSize.M),
              DataColumn2(label: Text('Statut'), size: ColumnSize.S),
              DataColumn2(label: Text('Date'), size: ColumnSize.M),
            ],
            rows: _samplePayments.map((p) {
              final statut = p['statut'] as String;
              Color statutColor;
              switch (statut) {
                case 'confirme':
                  statutColor = AppColors.success;
                  break;
                case 'en_attente':
                  statutColor = AppColors.warning;
                  break;
                default:
                  statutColor = AppColors.danger;
              }
              final statutLabels = {
                'confirme': 'Confirmé',
                'en_attente': 'En attente',
                'echoue': 'Échoué',
              };

              return DataRow2(cells: [
                DataCell(Text(p['id'] as String,
                    style: GoogleFonts.sourceCodePro(fontSize: 11))),
                DataCell(Text(p['apprenant'] as String)),
                DataCell(Text(p['cours'] as String,
                    style: const TextStyle(
                        color: AppColors.accentCyan, fontWeight: FontWeight.w600))),
                DataCell(Text(
                    '${formatter.format(p['montant'])} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(Text(_methodeLabel(p['methode'] as String))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statutLabels[statut] ?? statut,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statutColor),
                  ),
                )),
                DataCell(Text(dateFormat.format(p['date'] as DateTime))),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _methodeLabel(String m) {
    switch (m) {
      case 'orange_money': return 'Orange Money';
      case 'moov_money': return 'Moov Money';
      case 'wave': return 'Wave';
      case 'stripe': return 'Carte bancaire';
      default: return m;
    }
  }
}

class _CatalogueTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Gestion du catalogue',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('10 certifications · 30+ labs',
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un cours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesAdminTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Gestion des badges',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('893 badges émis · 100% blockchain vérifiés',
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Vérifier tous les badges'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentCyan,
              side: const BorderSide(color: AppColors.accentCyan),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConformiteTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('CIL Burkina Faso', 'Déclaration N° 2024-CIL-0847', true),
      ('RGPD (usage UE)', 'Politique confidentalité v2.1', true),
      ('Hébergement données', 'Serveurs localisés en Afrique', true),
      ('Chiffrement', 'TLS 1.3 · AES-256', true),
      ('Audit sécurité', 'Dernier audit: Mars 2026', true),
      ('Droit d\'accès', 'Formulaire DSAR disponible', true),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Conformité & Protection des données',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          ...items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.$3 ? Icons.check_circle : Icons.warning,
                      color: item.$3 ? AppColors.success : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          Text(item.$2,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Conforme',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Exporter rapport de conformité'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
