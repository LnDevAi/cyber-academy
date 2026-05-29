import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/courses_api.dart';
import '../../shared/models/course.dart';
import '../../shared/widgets/course_card.dart';

// Provider for catalog
final catalogueProvider = FutureProvider.autoDispose<List<Course>>((ref) async {
  final api = ref.read(coursesApiProvider);
  try {
    final data = await api.getCatalogue();
    return data.map((d) => Course.fromJson(d as Map<String, dynamic>)).toList();
  } catch (_) {
    // Return sample data if API not available
    return CourseData.sampleCourses
        .map((d) => Course.fromJson(d))
        .toList();
  }
});

class CataloguePage extends ConsumerStatefulWidget {
  const CataloguePage({super.key});

  @override
  ConsumerState<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends ConsumerState<CataloguePage> {
  String? _selectedBloc;
  String? _selectedType;
  String? _selectedNiveau;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogueAsync = ref.watch(catalogueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top bar
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/vitrine'),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'Catalogue des formations',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
                const Spacer(),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une formation...',
                      hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Connexion',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                ),
              ],
            ),
          ),
          // Filter row
          Container(
            color: AppColors.cardWhite,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
            child: Row(
              children: [
                Text('Filtrer par:',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                _FilterChip(
                    label: 'Tous les blocs',
                    isSelected: _selectedBloc == null,
                    onTap: () => setState(() => _selectedBloc = null)),
                const SizedBox(width: 8),
                ...[
                  ('A', 'Fondamentaux', AppColors.blocA),
                  ('B', 'Gouvernance', AppColors.blocB),
                  ('C', 'Offensif', AppColors.blocC),
                  ('D', 'Réseaux', AppColors.blocD),
                  ('E', 'Forensic', AppColors.blocE),
                ].map((b) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: 'Bloc ${b.$1}',
                        isSelected: _selectedBloc == b.$1,
                        color: b.$3,
                        onTap: () => setState(() =>
                            _selectedBloc = _selectedBloc == b.$1 ? null : b.$1),
                      ),
                    )),
                const SizedBox(width: 16),
                _FilterChip(
                    label: 'E-Cert',
                    isSelected: _selectedType == 'edefence',
                    color: AppColors.accentCyan,
                    onTap: () => setState(() =>
                        _selectedType = _selectedType == 'edefence' ? null : 'edefence')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'International',
                    isSelected: _selectedType == 'international',
                    color: AppColors.warning,
                    onTap: () => setState(() =>
                        _selectedType = _selectedType == 'international'
                            ? null
                            : 'international')),
                const Spacer(),
                catalogueAsync.when(
                  data: (courses) {
                    final filtered = _filterCourses(courses);
                    return Text(
                      '${filtered.length} formation${filtered.length > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 12),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: catalogueAsync.when(
              data: (courses) {
                final filtered = _filterCourses(courses);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune formation trouvée',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _selectedBloc = null;
                            _selectedType = null;
                            _search = '';
                            _searchCtrl.clear();
                          }),
                          child: const Text('Réinitialiser les filtres'),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(48),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => CourseCard(course: filtered[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'Impossible de charger le catalogue',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(catalogueProvider),
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

  List<Course> _filterCourses(List<Course> courses) {
    return courses.where((c) {
      if (_selectedBloc != null && c.bloc != _selectedBloc) return false;
      if (_selectedType != null && c.type != _selectedType) return false;
      if (_selectedNiveau != null && c.niveau != _selectedNiveau) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!c.titre.toLowerCase().contains(q) &&
            !c.code.toLowerCase().contains(q) &&
            !c.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accentBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? c : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
