import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import 'certifications_provider.dart';
import '../../shared/models/user.dart';

class CertificationsScreen extends ConsumerWidget {
  const CertificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certsAsync = ref.watch(certificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Certifications',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: certsAsync.when(
        data: (certs) {
          if (certs.isEmpty) {
            return _buildEmpty();
          }
          final obtained = certs.where((c) => c.status == 'obtenu' || c.status == 'passed').toList();
          final inProgress = certs.where((c) => c.status != 'obtenu' && c.status != 'passed').toList();

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => ref.invalidate(certificationsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (obtained.isNotEmpty) ...[
                  _buildSectionHeader('Certifications obtenues', obtained.length, AppColors.success),
                  ...obtained.map((c) => _CertCard(cert: c)),
                  const SizedBox(height: 8),
                ],
                if (inProgress.isNotEmpty) ...[
                  _buildSectionHeader('En cours', inProgress.length, AppColors.warning),
                  ...inProgress.map((c) => _CertCard(cert: c)),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.error, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(certificationsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                size: 40,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune certification',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complétez des parcours de formation\npour obtenir vos certifications',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final Certification cert;

  const _CertCard({required this.cert});

  bool get _isObtained => cert.status == 'obtenu' || cert.status == 'passed';

  Color get _statusColor => _isObtained ? AppColors.success : AppColors.warning;

  String get _statusLabel {
    switch (cert.status) {
      case 'obtenu':
      case 'passed':
        return 'Obtenue';
      case 'en_cours':
      case 'in_progress':
        return 'En cours';
      case 'echoue':
      case 'failed':
        return 'Échouée';
      default:
        return cert.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isObtained
              ? AppColors.success.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: _isObtained
                    ? const LinearGradient(
                        colors: [AppColors.success, Color(0xFF00A876)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _isObtained ? Icons.workspace_premium_rounded : Icons.pending_actions_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cert.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _statusColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          _statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cert.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (cert.score != null)
                        _MetaItem(
                          icon: Icons.assessment_outlined,
                          label: 'Score : ${cert.score!.toInt()}%',
                          color: cert.score! >= 70 ? AppColors.success : AppColors.warning,
                        ),
                      if (cert.obtainedAt != null)
                        _MetaItem(
                          icon: Icons.calendar_today_outlined,
                          label: DateFormat('dd/MM/yyyy').format(cert.obtainedAt!),
                        ),
                      if (cert.expiresAt != null)
                        _MetaItem(
                          icon: Icons.access_time_rounded,
                          label: 'Expire le ${DateFormat('dd/MM/yyyy').format(cert.expiresAt!)}',
                          color: cert.expiresAt!.isBefore(DateTime.now().add(const Duration(days: 30)))
                              ? AppColors.warning
                              : null,
                        ),
                    ],
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: c),
        ),
      ],
    );
  }
}
