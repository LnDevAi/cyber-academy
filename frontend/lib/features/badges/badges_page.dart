import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/badges_api.dart';
import '../../shared/models/badge.dart' as model;
import '../../shared/widgets/cyber_sidebar.dart';
import '../../shared/widgets/badge_card.dart';

final badgesListProvider = FutureProvider.autoDispose<List<model.Badge>>((ref) async {
  final api = ref.read(badgesApiProvider);
  try {
    final data = await api.listBadges();
    return data.map((d) => model.Badge.fromJson(d as Map<String, dynamic>)).toList();
  } catch (_) {
    // Sample badges
    return [
      model.Badge(
        id: 'badge-1',
        userId: '1',
        courseCode: 'A01-CYB',
        courseTitre: 'Fondamentaux de la Cybersécurité',
        imageUrl: '',
        dateEmission: DateTime.now().subtract(const Duration(days: 30)),
        blockchainVerifie: true,
        blockchainTxHash: '0x1234...abcd',
        blockchainVerifyUrl: 'https://verify.edefence.io/badge/badge-1',
        partenaireCode: 'E-DEFENCE',
        partenaireLogo: '',
        heuresCertifiees: 40,
      ),
      model.Badge(
        id: 'badge-2',
        userId: '1',
        courseCode: 'D01-NET',
        courseTitre: 'Sécurité des Réseaux & Infrastructures',
        imageUrl: '',
        dateEmission: DateTime.now().subtract(const Duration(days: 5)),
        blockchainVerifie: true,
        blockchainTxHash: '0x5678...efgh',
        blockchainVerifyUrl: 'https://verify.edefence.io/badge/badge-2',
        partenaireCode: 'E-DEFENCE',
        partenaireLogo: '',
        heuresCertifiees: 55,
      ),
    ];
  }
});

class BadgesPage extends ConsumerWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const CyberSidebar(currentRoute: '/dashboard/badges'),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(32),
                  color: AppColors.cardWhite,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes Badges & Certifications',
                            style: GoogleFonts.inter(
                                fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          badgesAsync.when(
                            data: (badges) => Text(
                              '${badges.length} certification${badges.length > 1 ? 's' : ''} · ${badges.where((b) => b.blockchainVerifie).length} vérifiée${badges.where((b) => b.blockchainVerifie).length > 1 ? 's' : ''} blockchain',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          Share.share(
                            'Découvrez mes certifications en cybersécurité E-DEFENCE: https://profile.edefence.io/1',
                          );
                        },
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Partager mon profil certifié'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentCyan,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                // Stats bar
                badgesAsync.when(
                  data: (badges) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        _StatBadge(
                          icon: Icons.workspace_premium,
                          value: '${badges.length}',
                          label: 'Badges totaux',
                          color: AppColors.accentCyan,
                        ),
                        const SizedBox(width: 24),
                        _StatBadge(
                          icon: Icons.verified,
                          value: '${badges.where((b) => b.blockchainVerifie).length}',
                          label: 'Vérifiés blockchain',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 24),
                        _StatBadge(
                          icon: Icons.timer,
                          value: '${badges.fold<int>(0, (s, b) => s + b.heuresCertifiees)}h',
                          label: 'Heures certifiées',
                          color: AppColors.accentBlue,
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(height: 60),
                  error: (_, __) => const SizedBox(height: 60),
                ),
                // Grid
                Expanded(
                  child: badgesAsync.when(
                    data: (badges) {
                      if (badges.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.workspace_premium_outlined,
                                    size: 40, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 20),
                              Text('Aucun badge encore',
                                  style: GoogleFonts.inter(
                                      fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(
                                'Complétez vos parcours pour obtenir vos certifications blockchain',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(32),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: badges.length,
                        itemBuilder: (ctx, i) => BadgeCard(badge: badges[i]),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.danger),
                          const SizedBox(height: 16),
                          Text('Erreur de chargement des badges',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(badgesListProvider),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
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

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
