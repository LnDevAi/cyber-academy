import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../models/course.dart';

class CourseCard extends StatefulWidget {
  final Course course;
  final VoidCallback? onEnroll;
  final bool showEnrollButton;

  const CourseCard({
    super.key,
    required this.course,
    this.onEnroll,
    this.showEnrollButton = true,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _hovered = false;

  Color get blocColor {
    switch (widget.course.bloc) {
      case 'A': return AppColors.blocA;
      case 'B': return AppColors.blocB;
      case 'C': return AppColors.blocC;
      case 'D': return AppColors.blocD;
      case 'E': return AppColors.blocE;
      default: return AppColors.accentBlue;
    }
  }

  IconData get blocIcon {
    switch (widget.course.bloc) {
      case 'A': return Icons.security;
      case 'B': return Icons.gavel;
      case 'C': return Icons.bug_report;
      case 'D': return Icons.router;
      case 'E': return Icons.find_in_page;
      default: return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/catalogue/${widget.course.code}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? blocColor.withOpacity(0.4) : AppColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: blocColor.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with bloc color
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: blocColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + code row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: blocColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(blocIcon, color: blocColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.course.code,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: blocColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              _TypeBadge(isEDefence: widget.course.isEDefence),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      widget.course.titre,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Text(
                      widget.course.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Info chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          icon: Icons.schedule,
                          label: '${widget.course.dureeHeures}h',
                        ),
                        _InfoChip(
                          icon: Icons.terminal_outlined,
                          label: '${widget.course.nombreLabs} labs',
                        ),
                        _InfoChip(
                          icon: Icons.bar_chart,
                          label: _niveauLabel(widget.course.niveau),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Partner
                    Row(
                      children: [
                        Icon(Icons.verified_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          widget.course.partenaire,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Price + CTA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${formatter.format(widget.course.prix)} FCFA',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (widget.course.paiementEchelonne)
                              Text(
                                'Paiement en 3x',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        if (widget.showEnrollButton)
                          ElevatedButton(
                            onPressed: widget.onEnroll ??
                                () => context.go('/catalogue/${widget.course.code}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blocColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              textStyle: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            child: const Text("S'inscrire"),
                          ),
                      ],
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

  String _niveauLabel(String niveau) {
    switch (niveau) {
      case 'debutant': return 'Débutant';
      case 'intermediaire': return 'Intermédiaire';
      case 'avance': return 'Avancé';
      default: return niveau;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isEDefence;
  const _TypeBadge({required this.isEDefence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isEDefence
            ? AppColors.accentCyan.withOpacity(0.12)
            : const Color(0xFFF59E0B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isEDefence ? 'E-Cert' : 'International',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isEDefence ? AppColors.accentCyan : const Color(0xFFF59E0B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
