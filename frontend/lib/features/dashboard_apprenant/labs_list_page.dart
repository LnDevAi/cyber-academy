import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/cyber_sidebar.dart';
import '../../shared/widgets/lab_tile.dart';
import 'parcour_detail_page.dart';

class LabsListPage extends ConsumerWidget {
  final String enrollmentId;
  const LabsListPage({super.key, required this.enrollmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labsAsync = ref.watch(labsForEnrollmentProvider(enrollmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          CyberSidebar(currentRoute: '/dashboard/parcours/$enrollmentId/labs'),
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  color: AppColors.primaryDark,
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 20),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => context.go('/dashboard/parcours/$enrollmentId'),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white54, size: 16),
                        label: Text('Mon parcours',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 13)),
                      ),
                      const Spacer(),
                      labsAsync.when(
                        data: (labs) => Text(
                          '${labs.where((l) => l.isTermine).length}/${labs.length} labs complétés',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 13),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.primaryDark,
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, color: AppColors.accentCyan, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Cyber Range — Labs pratiques',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: labsAsync.when(
                    data: (labs) {
                      final completed = labs.where((l) => l.isTermine).length;
                      final total = labs.length;

                      return ListView(
                        padding: const EdgeInsets.all(32),
                        children: [
                          // Progress summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: completed == total
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                    size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  '$completed labs terminés sur $total',
                                  style: GoogleFonts.inter(fontSize: 14),
                                ),
                                const Spacer(),
                                if (completed < total)
                                  Text(
                                    '${total - completed} restant${total - completed > 1 ? 's' : ''}',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          ...labs.map((lab) => LabTile(
                                lab: lab,
                                onLaunch: () => context.go(
                                    '/dashboard/parcours/$enrollmentId/labs/${lab.id}'),
                              )),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.danger),
                          const SizedBox(height: 16),
                          Text('Erreur de chargement des labs',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(
                                labsForEnrollmentProvider(enrollmentId)),
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
