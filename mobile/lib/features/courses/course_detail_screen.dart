import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'courses_provider.dart';
import '../../shared/models/user.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseId));
    final lessonsAsync = ref.watch(lessonsProvider(courseId));
    final enrollmentState = ref.watch(enrollmentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: courseAsync.when(
        data: (course) => CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, course),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStats(course),
                    const SizedBox(height: 20),
                    _buildDescription(course),
                    const SizedBox(height: 20),
                    _buildLessonsSection(context, lessonsAsync, course),
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
      bottomNavigationBar: courseAsync.when(
        data: (course) => _buildBottomBar(context, ref, course, enrollmentState),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Course course) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: course.isEnrolled
                ? AppColors.cyberGradient
                : AppColors.primaryGradient,
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white.withOpacity(0.2),
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
                    LevelBadge(level: course.level),
                    const SizedBox(height: 8),
                    Text(
                      course.title,
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

  Widget _buildStats(Course course) {
    return Row(
      children: [
        _InfoChip(icon: Icons.timer_outlined, label: '${course.duration}h'),
        const SizedBox(width: 8),
        _InfoChip(icon: Icons.menu_book_outlined, label: '${course.lessonsCount} leçons'),
        const SizedBox(width: 8),
        _InfoChip(
          icon: Icons.people_outline_rounded,
          label: '${course.enrolledCount} inscrits',
        ),
        const SizedBox(width: 8),
        if (course.rating > 0)
          _InfoChip(
            icon: Icons.star_rounded,
            label: course.rating.toStringAsFixed(1),
            color: AppColors.warning,
          ),
      ],
    );
  }

  Widget _buildDescription(Course course) {
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
          course.description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsSection(
    BuildContext context,
    AsyncValue<List<Lesson>> lessonsAsync,
    Course course,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Programme',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        lessonsAsync.when(
          data: (lessons) => lessons.isEmpty
              ? Text(
                  'Aucune leçon disponible',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                )
              : Column(
                  children: lessons
                      .map(
                        (lesson) => _LessonTile(
                          lesson: lesson,
                          courseId: courseId,
                          isUnlocked: course.isEnrolled,
                        ),
                      )
                      .toList(),
                ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
          ),
          error: (e, _) => Text(
            e.toString(),
            style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    Course course,
    AsyncValue<void> enrollmentState,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: CyberButton(
        label: course.isEnrolled
            ? (course.progressPercent != null && course.progressPercent! > 0
                ? 'Continuer le cours'
                : 'Commencer le cours')
            : "S'inscrire au cours",
        isLoading: enrollmentState.isLoading,
        icon: course.isEnrolled ? Icons.play_arrow_rounded : Icons.add_circle_outline_rounded,
        width: double.infinity,
        onPressed: () async {
          if (course.isEnrolled) {
            context.go('/courses/$courseId/learn');
          } else {
            final ok = await ref.read(enrollmentProvider.notifier).enroll(courseId);
            if (ok && context.mounted) {
              ref.invalidate(courseDetailProvider(courseId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Inscription réussie ! Bonne formation.'),
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: c),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final String courseId;
  final bool isUnlocked;

  const _LessonTile({
    required this.lesson,
    required this.courseId,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked
          ? () => context.go('/courses/$courseId/learn?lessonId=${lesson.id}')
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: lesson.isCompleted
                ? AppColors.success.withOpacity(0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lesson.isCompleted
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.surfaceVariant,
                border: Border.all(
                  color: lesson.isCompleted ? AppColors.success : AppColors.border,
                ),
              ),
              child: Center(
                child: lesson.isCompleted
                    ? const Icon(Icons.check_rounded, color: AppColors.success, size: 16)
                    : Text(
                        '${lesson.order}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${lesson.duration} min',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (!isUnlocked)
              const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18)
            else
              Icon(
                Icons.play_circle_outline_rounded,
                color: AppColors.accent.withOpacity(0.7),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
