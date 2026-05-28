import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../certifications/certifications_provider.dart';
import '../courses/courses_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final certsAsync = ref.watch(certificationsProvider);
    final coursesAsync = ref.watch(coursesListProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.accent),
              const SizedBox(height: 16),
              Text(
                'Chargement du profil...',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final level = user.level;
    final xp = user.xpPoints;
    final xpForNextLevel = level * 500;
    final progress = (xp % xpForNextLevel) / xpForNextLevel;

    final certsCount = certsAsync.when(
      data: (list) => list.where((c) => c.status == 'obtenu' || c.status == 'passed').length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final enrolledCount = coursesAsync.when(
      data: (list) => list.where((c) => c.isEnrolled).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF150A2E), AppColors.primary, AppColors.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularPercentIndicator(
                          radius: 50,
                          lineWidth: 4,
                          percent: progress.clamp(0.0, 1.0),
                          backgroundColor: AppColors.border,
                          linearGradient: AppColors.cyberGradient,
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: Center(
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : 'A',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppColors.cyberGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Niveau $level',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildXpBar(xp, xpForNextLevel, progress),
                  const SizedBox(height: 24),
                  _buildStatsGrid(
                    xp,
                    user.streakDays,
                    enrolledCount,
                    user.coursesCompleted,
                    user.labsCompleted,
                    certsCount,
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(user),
                  const SizedBox(height: 24),
                  _buildActionsSection(context, ref),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar(int xp, int xpForNextLevel, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression XP',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$xp / $xpForNextLevel XP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    int xp,
    int streak,
    int enrolled,
    int completed,
    int labs,
    int certs,
  ) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _StatCell(icon: Icons.bolt_rounded, value: '$xp', label: 'XP Total', color: AppColors.accent),
        _StatCell(icon: Icons.local_fire_department, value: '$streak', label: 'Jours streak', color: AppColors.warning),
        _StatCell(icon: Icons.school_outlined, value: '$enrolled', label: 'Inscrits', color: AppColors.info),
        _StatCell(icon: Icons.check_circle_outline_rounded, value: '$completed', label: 'Cours finis', color: AppColors.success),
        _StatCell(icon: Icons.terminal_rounded, value: '$labs', label: 'Labs réussis', color: AppColors.accent),
        _StatCell(icon: Icons.workspace_premium_outlined, value: '$certs', label: 'Certifs', color: AppColors.primaryLight),
      ],
    );
  }

  Widget _buildInfoSection(user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
          const Divider(height: 16),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Rôle',
            value: user.role.replaceAll('_', ' ').capitalize(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.leaderboard_rounded,
          label: 'Classement',
          color: AppColors.accent,
          onTap: () => context.go('/leaderboard'),
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.settings_outlined,
          label: 'Paramètres',
          color: AppColors.textSecondary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paramètres — à venir')),
            );
          },
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.logout_rounded,
          label: 'Se déconnecter',
          color: AppColors.error,
          isDestructive: true,
          onTap: () => _confirmLogout(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Déconnexion',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(
          '$label :',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDestructive ? AppColors.error.withOpacity(0.08) : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive ? AppColors.error.withOpacity(0.3) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive ? AppColors.error.withOpacity(0.5) : AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
