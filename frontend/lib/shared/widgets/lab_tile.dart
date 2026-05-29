import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../models/cyber_range_session.dart';

class LabTile extends StatelessWidget {
  final Lab lab;
  final VoidCallback? onLaunch;

  const LabTile({super.key, required this.lab, this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Lab number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${lab.ordre}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lab.titre,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Difficulty stars
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < lab.difficulte ? Icons.star : Icons.star_outline,
                          size: 12,
                          color: i < lab.difficulte
                              ? AppColors.warning
                              : AppColors.textMuted,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      '${lab.dureeMinutes} min',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status chip
          _StatusChip(statut: lab.statut),
          const SizedBox(width: 12),
          // Launch button
          if (lab.isDisponible || lab.isEnCours)
            ElevatedButton.icon(
              onPressed: lab.isVerrouille ? null : onLaunch,
              icon: Icon(
                lab.isEnCours ? Icons.play_arrow : Icons.rocket_launch,
                size: 14,
              ),
              label: Text(lab.isEnCours ? 'Reprendre' : 'Lancer'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    lab.isEnCours ? AppColors.warning : AppColors.accentCyan,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else if (lab.isTermine)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Terminé',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Verrouillé',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (lab.statut) {
      case 'disponible': return AppColors.accentCyan;
      case 'en_cours': return AppColors.warning;
      case 'termine': return AppColors.success;
      case 'verrouille': return AppColors.textMuted;
      default: return AppColors.accentBlue;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String statut;
  const _StatusChip({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (statut) {
      case 'disponible':
        color = AppColors.accentCyan;
        label = 'Disponible';
        break;
      case 'en_cours':
        color = AppColors.warning;
        label = 'En cours';
        break;
      case 'termine':
        color = AppColors.success;
        label = 'Terminé';
        break;
      case 'verrouille':
        color = AppColors.textMuted;
        label = 'Verrouillé';
        break;
      default:
        color = AppColors.textMuted;
        label = statut;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
