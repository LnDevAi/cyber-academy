import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'labs_provider.dart';

class LabDetailScreen extends ConsumerWidget {
  final String labId;

  const LabDetailScreen({super.key, required this.labId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labAsync = ref.watch(labDetailProvider(labId));
    final sessionState = ref.watch(labSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: labAsync.when(
        data: (lab) => CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, lab),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(lab),
                    const SizedBox(height: 20),
                    _buildDescription(lab),
                    const SizedBox(height: 20),
                    _buildObjectives(lab),
                    if (sessionState.session != null) ...[
                      const SizedBox(height: 20),
                      _buildSessionInfo(context, ref, sessionState),
                    ],
                    if (sessionState.error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(context, ref, sessionState.error!),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Text(e.toString(), style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
      bottomNavigationBar: labAsync.when(
        data: (lab) => _buildBottomBar(context, ref, lab, sessionState),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, lab) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002B3D), AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.terminal_rounded,
                  color: Colors.white.withOpacity(0.15),
                  size: 120,
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LevelBadge(level: lab.difficulty),
                    const SizedBox(height: 8),
                    Text(
                      lab.title,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(lab) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _InfoPill(
          icon: Icons.code_rounded,
          label: lab.technology,
          color: AppColors.info,
        ),
        _InfoPill(
          icon: Icons.timer_outlined,
          label: '${lab.duration} min',
          color: AppColors.textSecondary,
        ),
        if (lab.isCompleted)
          _InfoPill(
            icon: Icons.check_circle_rounded,
            label: 'Complété',
            color: AppColors.success,
          ),
      ],
    );
  }

  Widget _buildDescription(lab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          lab.description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectives(lab) {
    if (lab.objectives.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectifs',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...lab.objectives.map(
          (obj) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.accent, size: 12),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    obj,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionInfo(BuildContext context, WidgetRef ref, LabSessionState state) {
    final session = state.session!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'Session démarrée',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (session['access_url'] != null) ...[
            Text(
              'URL d\'accès :',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
            ),
            Text(
              session['access_url'].toString(),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (session['credentials'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Identifiants : ${session['credentials']}',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, WidgetRef ref, String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(labSessionProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    lab,
    LabSessionState sessionState,
  ) {
    final hasSession = sessionState.session != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: CyberButton(
        label: hasSession ? 'Session en cours...' : 'Démarrer le lab',
        isLoading: sessionState.isLoading,
        icon: hasSession ? Icons.play_circle_filled_rounded : Icons.rocket_launch_rounded,
        width: double.infinity,
        onPressed: hasSession
            ? null
            : () async {
                final ok = await ref.read(labSessionProvider.notifier).startSession(labId);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Lab démarré ! Bonne pratique.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
