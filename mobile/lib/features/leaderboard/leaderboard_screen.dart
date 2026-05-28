import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/models/user.dart';
import '../auth/auth_provider.dart';
import 'package:dio/dio.dart';

// Provider leaderboard
final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final response = await api.get('/leaderboard/');
    final data = response.data;
    final list = data is List ? data : (data['results'] ?? data['leaderboard'] ?? []);
    return (list as List)
        .asMap()
        .entries
        .map((entry) => LeaderboardEntry.fromJson(
              entry.value as Map<String, dynamic>,
            ))
        .toList();
  } on DioException catch (e) {
    throw extractApiError(e);
  }
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Classement',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: () => ref.invalidate(leaderboardProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmpty();
          }
          // Mark current user
          final enriched = entries.map((e) {
            return LeaderboardEntry(
              rank: e.rank,
              userId: e.userId,
              username: e.username,
              avatar: e.avatar,
              xpPoints: e.xpPoints,
              coursesCompleted: e.coursesCompleted,
              isCurrentUser: e.userId == currentUserId,
            );
          }).toList();

          final top3 = enriched.take(3).toList();
          final rest = enriched.skip(3).toList();
          final currentUser = enriched.where((e) => e.isCurrentUser).firstOrNull;

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => ref.invalidate(leaderboardProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildPodium(top3)),
                if (rest.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _LeaderboardTile(
                        entry: rest[index],
                        isCurrentUser: rest[index].isCurrentUser,
                      ),
                      childCount: rest.length,
                    ),
                  ),
                if (currentUser != null && currentUser.rank > 10)
                  SliverToBoxAdapter(
                    child: _buildMyRankBanner(currentUser),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                onPressed: () => ref.invalidate(leaderboardProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF150A2E), Color(0xFF0A1535)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'TOP 3',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (top3.length > 1) _PodiumEntry(entry: top3[1], position: 2),
              const SizedBox(width: 16),
              _PodiumEntry(entry: top3[0], position: 1),
              const SizedBox(width: 16),
              if (top3.length > 2) _PodiumEntry(entry: top3[2], position: 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankBanner(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cyberGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre position',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  entry.username,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xpPoints}',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'XP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.leaderboard_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Classement non disponible',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  final LeaderboardEntry entry;
  final int position;

  const _PodiumEntry({required this.entry, required this.position});

  Color get _medalColor {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }

  double get _avatarSize => position == 1 ? 72.0 : 58.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (entry.isCurrentUser)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: AppColors.cyberGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Vous',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: _avatarSize,
              height: _avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _medalColor.withOpacity(0.8),
                    _medalColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _medalColor, width: 2),
              ),
              child: Center(
                child: Text(
                  entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    fontSize: position == 1 ? 28 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _medalColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.xpPoints} XP',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _medalColor,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardTile({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withOpacity(0.12) : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser ? AppColors.primaryLight.withOpacity(0.5) : AppColors.border,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCurrentUser ? AppColors.primaryLight : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCurrentUser ? AppColors.cyberGradient : AppColors.primaryGradient,
            ),
            child: Center(
              child: Text(
                entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.username,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: AppColors.cyberGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Vous',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${entry.coursesCompleted} cours complétés',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xpPoints}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isCurrentUser ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              Text(
                'XP',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
