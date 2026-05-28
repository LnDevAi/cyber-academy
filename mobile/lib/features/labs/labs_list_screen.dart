import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'labs_provider.dart';
import '../../shared/models/user.dart';

class LabsListScreen extends ConsumerStatefulWidget {
  const LabsListScreen({super.key});

  @override
  ConsumerState<LabsListScreen> createState() => _LabsListScreenState();
}

class _LabsListScreenState extends ConsumerState<LabsListScreen> {
  final _searchCtrl = TextEditingController();
  final _difficulties = ['Tous', 'Débutant', 'Intermédiaire', 'Avancé', 'Expert'];
  String _selectedDifficulty = 'Tous';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredLabsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Cyber Labs',
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
          _buildDifficultyFilter(),
          Expanded(
            child: filteredAsync.when(
              data: (labs) => labs.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: () async => ref.invalidate(labsListProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: labs.length,
                        itemBuilder: (context, index) => _LabCard(lab: labs[index]),
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
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.error, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(labsListProvider),
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
            .read(labFiltersProvider.notifier)
            .update((s) => s.copyWith(search: v.isEmpty ? null : v)),
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher un lab...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref
                        .read(labFiltersProvider.notifier)
                        .update((s) => s.copyWith(search: null));
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _difficulties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final diff = _difficulties[index];
          final isSelected = _selectedDifficulty == diff;
          return FilterChip(
            label: Text(diff),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedDifficulty = diff);
              ref.read(labFiltersProvider.notifier).update(
                (s) => s.copyWith(difficulty: diff == 'Tous' ? null : diff),
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
          const Icon(Icons.terminal_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Aucun lab trouvé',
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

class _LabCard extends StatelessWidget {
  final Lab lab;

  const _LabCard({required this.lab});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/labs/${lab.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: lab.isCompleted
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
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.terminal_rounded, color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lab.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (lab.isCompleted)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lab.description,
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
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        LevelBadge(level: lab.difficulty),
                        _TechBadge(tech: lab.technology),
                        _DurationBadge(minutes: lab.duration),
                        if (lab.sessionStatus != null)
                          _StatusBadge(status: lab.sessionStatus!),
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
}

class _TechBadge extends StatelessWidget {
  final String tech;

  const _TechBadge({required this.tech});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.code_rounded, size: 12, color: AppColors.info),
          const SizedBox(width: 4),
          Text(
            tech,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  final int minutes;

  const _DurationBadge({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          '${minutes}min',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'running':
      case 'actif':
        return AppColors.success;
      case 'pending':
      case 'en attente':
        return AppColors.warning;
      case 'stopped':
      case 'arrêté':
        return AppColors.textMuted;
      default:
        return AppColors.info;
    }
  }

  String get _label {
    switch (status.toLowerCase()) {
      case 'running':
        return 'En cours';
      case 'pending':
        return 'En attente';
      case 'stopped':
        return 'Arrêté';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
