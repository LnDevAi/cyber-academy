import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/theme.dart';
import 'courses_provider.dart';
import '../../shared/models/user.dart';

class CoursesCatalogScreen extends ConsumerStatefulWidget {
  const CoursesCatalogScreen({super.key});

  @override
  ConsumerState<CoursesCatalogScreen> createState() => _CoursesCatalogScreenState();
}

class _CoursesCatalogScreenState extends ConsumerState<CoursesCatalogScreen> {
  final _searchCtrl = TextEditingController();

  final _levels = ['Tous', 'Débutant', 'Intermédiaire', 'Avancé', 'Expert'];
  final _categories = [
    'Tous',
    'Fondamentaux',
    'Gouvernance',
    'Offensif',
    'Réseaux',
    'Forensic',
  ];

  String _selectedLevel = 'Tous';
  String _selectedCategory = 'Tous';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredCoursesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Catalogue des cours',
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
      body: Column(
        children: [
          _buildSearchBar(),
          _buildLevelFilter(),
          _buildCategoryFilter(),
          Expanded(
            child: filteredAsync.when(
              data: (courses) => courses.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: () async => ref.invalidate(coursesListProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: courses.length,
                        itemBuilder: (context, index) =>
                            _CourseCard(course: courses[index]),
                      ),
                    ),
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
                      style: GoogleFonts.inter(color: AppColors.error, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(coursesListProvider),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => ref
            .read(courseFiltersProvider.notifier)
            .update((s) => s.copyWith(search: v.isEmpty ? null : v)),
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher un cours...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref
                        .read(courseFiltersProvider.notifier)
                        .update((s) => s.copyWith(search: null));
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLevelFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = _levels[index];
          final isSelected = _selectedLevel == level;
          return FilterChip(
            label: Text(level),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedLevel = level);
              ref.read(courseFiltersProvider.notifier).update(
                (s) => s.copyWith(level: level == 'Tous' ? null : level),
              );
            },
            selectedColor: AppColors.primary.withOpacity(0.3),
            labelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primaryLight : AppColors.border,
            ),
            backgroundColor: AppColors.surfaceVariant,
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return FilterChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedCategory = cat);
              ref.read(courseFiltersProvider.notifier).update(
                (s) => s.copyWith(category: cat == 'Tous' ? null : cat),
              );
            },
            selectedColor: AppColors.accent.withOpacity(0.2),
            labelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.accent : AppColors.border,
            ),
            backgroundColor: AppColors.surfaceVariant,
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Aucun cours trouvé',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/courses/${course.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail ou placeholder
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: course.isEnrolled
                    ? AppColors.cyberGradient
                    : AppColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white.withOpacity(0.3),
                      size: 72,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: LevelBadge(level: course.level),
                  ),
                  if (course.isEnrolled)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Inscrit',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${course.duration}h',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.menu_book_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${course.lessonsCount} leçons',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people_outline_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${course.enrolledCount}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  if (course.isEnrolled && (course.progressPercent ?? 0) > 0) ...[
                    const SizedBox(height: 10),
                    LinearPercentIndicator(
                      percent: ((course.progressPercent ?? 0) / 100).clamp(0.0, 1.0),
                      lineHeight: 5,
                      backgroundColor: AppColors.border,
                      linearGradient: AppColors.cyberGradient,
                      barRadius: const Radius.circular(3),
                      padding: EdgeInsets.zero,
                      trailing: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '${(course.progressPercent ?? 0).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
