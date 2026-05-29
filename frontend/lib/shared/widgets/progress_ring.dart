import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme/app_theme.dart';

class ProgressRing extends StatelessWidget {
  final double percent; // 0-100
  final double radius;
  final double lineWidth;
  final bool showLabel;

  const ProgressRing({
    super.key,
    required this.percent,
    this.radius = 60,
    this.lineWidth = 8,
    this.showLabel = true,
  });

  Color get _color {
    if (percent < 30) return AppColors.danger;
    if (percent < 70) return AppColors.warning;
    return AppColors.accentCyan;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = (percent / 100).clamp(0.0, 1.0);

    return CircularPercentIndicator(
      radius: radius,
      lineWidth: lineWidth,
      percent: normalized,
      center: showLabel
          ? Text(
              '${percent.round()}%',
              style: GoogleFonts.inter(
                fontSize: radius * 0.28,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            )
          : null,
      progressColor: _color,
      backgroundColor: _color.withOpacity(0.12),
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 800,
    );
  }
}

class LinearProgressBar extends StatelessWidget {
  final double percent; // 0-100
  final double height;
  final String? label;

  const LinearProgressBar({
    super.key,
    required this.percent,
    this.height = 8,
    this.label,
  });

  Color get _color {
    if (percent < 30) return AppColors.danger;
    if (percent < 70) return AppColors.warning;
    return AppColors.accentCyan;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = (percent / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${percent.round()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: height,
            backgroundColor: _color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
        ),
      ],
    );
  }
}
