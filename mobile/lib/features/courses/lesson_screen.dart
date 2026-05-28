import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme.dart';
import 'courses_provider.dart';
import '../../shared/models/user.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String? lessonId;

  const LessonScreen({super.key, required this.courseId, this.lessonId});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _isMarkingComplete = false;

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsProvider(widget.courseId));

    return lessonsAsync.when(
      data: (lessons) {
        if (lessons.isEmpty) {
          return _buildEmpty(context);
        }

        Lesson currentLesson;
        int currentIndex;

        if (widget.lessonId != null) {
          currentIndex = lessons.indexWhere((l) => l.id == widget.lessonId);
          if (currentIndex == -1) currentIndex = 0;
        } else {
          currentIndex = lessons.indexWhere((l) => !l.isCompleted);
          if (currentIndex == -1) currentIndex = 0;
        }
        currentLesson = lessons[currentIndex];

        final hasPrevious = currentIndex > 0;
        final hasNext = currentIndex < lessons.length - 1;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leçon ${currentIndex + 1} / ${lessons.length}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  currentLesson.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              if (currentLesson.isCompleted)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.check_circle_rounded, color: AppColors.success),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: (currentIndex + 1) / lessons.length,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                minHeight: 3,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _LessonContent(lesson: currentLesson),
              ),
              _buildNavBar(
                context,
                ref,
                lessons,
                currentLesson,
                currentIndex,
                hasPrevious,
                hasNext,
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
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
    );
  }

  Widget _buildNavBar(
    BuildContext context,
    WidgetRef ref,
    List<Lesson> lessons,
    Lesson currentLesson,
    int currentIndex,
    bool hasPrevious,
    bool hasNext,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (hasPrevious)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final prev = lessons[currentIndex - 1];
                  context.go('/courses/${widget.courseId}/learn?lessonId=${prev.id}');
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Précédente'),
              ),
            ),
          if (hasPrevious && (hasNext || !currentLesson.isCompleted))
            const SizedBox(width: 12),
          if (!currentLesson.isCompleted || hasNext)
            Expanded(
              child: CyberButton(
                label: currentLesson.isCompleted
                    ? 'Leçon suivante'
                    : hasNext
                        ? 'Marquer et suivant'
                        : 'Terminer le cours',
                isLoading: _isMarkingComplete,
                icon: currentLesson.isCompleted
                    ? Icons.arrow_forward_rounded
                    : Icons.check_rounded,
                onPressed: () async {
                  if (!currentLesson.isCompleted) {
                    setState(() => _isMarkingComplete = true);
                    await ref
                        .read(enrollmentProvider.notifier)
                        .markLessonComplete(widget.courseId, currentLesson.id);
                    ref.invalidate(lessonsProvider(widget.courseId));
                    setState(() => _isMarkingComplete = false);
                  }
                  if (hasNext && context.mounted) {
                    final next = lessons[currentIndex + 1];
                    context.go('/courses/${widget.courseId}/learn?lessonId=${next.id}');
                  } else if (context.mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Félicitations ! Cours terminé.'),
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
            ),
        ],
      ),
    );
  }

  Scaffold _buildEmpty(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Leçons'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Aucune leçon disponible',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonContent extends StatelessWidget {
  final Lesson lesson;

  const _LessonContent({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: lesson.content.isNotEmpty
          ? lesson.content
          : '_Contenu de la leçon non disponible._',
      padding: const EdgeInsets.all(20),
      styleSheet: MarkdownStyleSheet(
        h1: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        h2: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        h3: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        p: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.7,
        ),
        strong: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        em: GoogleFonts.inter(
          fontStyle: FontStyle.italic,
          color: AppColors.textSecondary,
        ),
        code: GoogleFonts.sourceCodePro(
          fontSize: 13,
          color: AppColors.accent,
          backgroundColor: AppColors.surfaceVariant,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
        ),
        blockquotePadding: const EdgeInsets.all(16),
        blockquote: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        listBullet: GoogleFonts.inter(color: AppColors.accent, fontSize: 14),
        tableHead: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        tableBody: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        tableBorder: TableBorder.all(color: AppColors.border, width: 1),
        tableHeadAlign: TextAlign.left,
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
      ),
    );
  }
}
