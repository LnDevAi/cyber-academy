import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import 'range_provider.dart';

class CyberRangePage extends ConsumerStatefulWidget {
  final String enrollmentId;
  final String labId;

  const CyberRangePage({
    super.key,
    required this.enrollmentId,
    required this.labId,
  });

  @override
  ConsumerState<CyberRangePage> createState() => _CyberRangePageState();
}

class _CyberRangePageState extends ConsumerState<CyberRangePage> {
  bool _showPanel = true;
  int _revealedHints = 0;
  final _notesCtrl = TextEditingController();
  WebViewController? _webController;
  int _activeTab = 0; // 0=objectifs, 1=hints, 2=notes

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(
        rangeSessionProvider((widget.labId, widget.enrollmentId)));
    final hintsAsync = ref.watch(labHintsProvider(widget.labId));

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Column(
        children: [
          // Top bar
          Container(
            height: 52,
            color: const Color(0xFF1e293b),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _confirmStop(sessionState),
                  icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 18),
                  tooltip: 'Quitter',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.terminal, color: AppColors.accentCyan, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lab ${widget.labId} — Cyber Range E-DEFENCE',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 13, color: AppColors.accentCyan),
                      const SizedBox(width: 6),
                      Text(
                        ref
                            .read(rangeSessionProvider(
                                (widget.labId, widget.enrollmentId))
                                .notifier)
                            .formattedTime,
                        style: GoogleFonts.sourceCodePro(
                            color: AppColors.accentCyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status chip
                _StatusChip(statut: sessionState.session?.statut ?? 'demarrage'),
                const SizedBox(width: 12),
                // Toggle panel
                IconButton(
                  onPressed: () => setState(() => _showPanel = !_showPanel),
                  icon: Icon(
                    _showPanel ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white54,
                    size: 18,
                  ),
                  tooltip: 'Panneau latéral',
                ),
                const SizedBox(width: 8),
                // Stop button
                ElevatedButton.icon(
                  onPressed: () => _confirmStop(sessionState),
                  icon: const Icon(Icons.stop_circle_outlined, size: 14),
                  label: const Text('Terminer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Row(
              children: [
                // WebView area
                Expanded(
                  child: _buildWebViewArea(sessionState),
                ),
                // Side panel
                if (_showPanel) _buildSidePanel(hintsAsync),
              ],
            ),
          ),
          // Bottom status bar
          Container(
            height: 28,
            color: const Color(0xFF0c1a2e),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: sessionState.session?.isActive == true
                        ? AppColors.success
                        : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  sessionState.session?.statut == 'actif'
                      ? 'Connecté — Session active'
                      : 'Démarrage de l\'environnement...',
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 10),
                ),
                const Spacer(),
                Text(
                  'k3s + Apache Guacamole',
                  style: GoogleFonts.inter(
                      color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebViewArea(RangeSessionState sessionState) {
    if (sessionState.isLoading || sessionState.session == null) {
      return Container(
        color: AppColors.primaryDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.accentCyan),
              const SizedBox(height: 20),
              Text(
                'Démarrage de l\'environnement virtuel...',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Provisionnement k3s en cours',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (sessionState.error != null) {
      return Container(
        color: AppColors.primaryDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text(sessionState.error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.invalidate(rangeSessionProvider(
                    (widget.labId, widget.enrollmentId))),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final url = sessionState.session?.guacamoleUrl ??
        'http://localhost:8080/guacamole/#/?lab=${widget.labId}';

    // For web platform, we use WebView
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(url));

      return WebViewWidget(controller: controller);
    } catch (e) {
      // Fallback for environments where webview is not available
      return Container(
        color: const Color(0xFF0f172a),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.computer, size: 64, color: AppColors.accentCyan),
              const SizedBox(height: 20),
              Text(
                'Cyber Range',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                url,
                style: GoogleFonts.sourceCodePro(
                    color: AppColors.accentCyan, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Text(
                'Interface Guacamole disponible via le navigateur',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSidePanel(AsyncValue<List<String>> hintsAsync) {
    return Container(
      width: 320,
      color: const Color(0xFF1e293b),
      child: Column(
        children: [
          // Tab bar
          Container(
            color: const Color(0xFF0f172a),
            child: Row(
              children: [
                _PanelTab(
                    label: 'Objectifs',
                    index: 0,
                    active: _activeTab == 0,
                    onTap: () => setState(() => _activeTab = 0)),
                _PanelTab(
                    label: 'Indices',
                    index: 1,
                    active: _activeTab == 1,
                    onTap: () => setState(() => _activeTab = 1)),
                _PanelTab(
                    label: 'Notes',
                    index: 2,
                    active: _activeTab == 2,
                    onTap: () => setState(() => _activeTab = 2)),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _activeTab == 0
                ? _ObjectifsPanel()
                : _activeTab == 1
                    ? _HintsPanel(
                        hintsAsync: hintsAsync,
                        revealedHints: _revealedHints,
                        onReveal: () =>
                            setState(() => _revealedHints++),
                      )
                    : _NotesPanel(controller: _notesCtrl),
          ),
        ],
      ),
    );
  }

  void _confirmStop(RangeSessionState sessionState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Terminer la session?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Votre progression dans ce lab sera sauvegardée. Vous pourrez reprendre plus tard.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Continuer')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(rangeSessionProvider(
                          (widget.labId, widget.enrollmentId))
                      .notifier)
                  .stopSession();
              if (mounted) {
                context.go('/dashboard/parcours/${widget.enrollmentId}/labs');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, elevation: 0),
            child: const Text('Terminer la session'),
          ),
        ],
      ),
    );
  }
}

class _PanelTab extends StatelessWidget {
  final String label;
  final int index;
  final bool active;
  final VoidCallback onTap;
  const _PanelTab({
    required this.label,
    required this.index,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.accentCyan : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: active ? AppColors.accentCyan : Colors.white38,
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ObjectifsPanel extends StatelessWidget {
  final _objectifs = [
    'Effectuer une reconnaissance réseau complète',
    'Identifier les services vulnérables',
    'Exploiter la vulnérabilité SQL Injection',
    'Extraire les credentials de la base de données',
    'Obtenir un accès shell sur le serveur cible',
    'Rédiger les conclusions dans le rapport',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Objectifs du lab',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        ..._objectifs.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0f172a),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: GoogleFonts.inter(
                            color: AppColors.accentCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _HintsPanel extends StatelessWidget {
  final AsyncValue<List<String>> hintsAsync;
  final int revealedHints;
  final VoidCallback onReveal;

  const _HintsPanel({
    required this.hintsAsync,
    required this.revealedHints,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return hintsAsync.when(
      data: (hints) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Indices',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '${revealedHints}/${hints.length} indices révélés',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 14),
          ...hints.asMap().entries.map((e) {
            final i = e.key;
            final hint = e.value;
            final revealed = i < revealedHints;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: revealed
                    ? const Color(0xFF0f172a)
                    : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: revealed
                      ? AppColors.accentCyan.withOpacity(0.3)
                      : const Color(0xFF334155),
                ),
              ),
              child: revealed
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Indice ${i + 1}',
                            style: GoogleFonts.inter(
                                color: AppColors.accentCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(hint,
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4)),
                      ],
                    )
                  : GestureDetector(
                      onTap: i == revealedHints ? onReveal : null,
                      child: Row(
                        children: [
                          Icon(
                            i == revealedHints
                                ? Icons.lock_open_outlined
                                : Icons.lock_outlined,
                            size: 14,
                            color: i == revealedHints
                                ? AppColors.accentCyan
                                : Colors.white24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            i == revealedHints
                                ? 'Révéler l\'indice ${i + 1}'
                                : 'Indice ${i + 1} — verrouillé',
                            style: GoogleFonts.inter(
                              color: i == revealedHints
                                  ? AppColors.accentCyan
                                  : Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          }),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
          child: Text('Indices indisponibles',
              style: GoogleFonts.inter(color: Colors.white54))),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  final TextEditingController controller;
  const _NotesPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes personnelles',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: GoogleFonts.sourceCodePro(color: Colors.white70, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Prendre des notes pendant le lab...\n\nnmap -sV 10.0.0.1\n...',
                hintStyle: GoogleFonts.sourceCodePro(
                    color: Colors.white24, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF0f172a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.accentCyan, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
      case 'actif':
        color = AppColors.success;
        label = 'Connecté';
        break;
      case 'demarrage':
        color = AppColors.warning;
        label = 'Démarrage...';
        break;
      case 'termine':
        color = AppColors.textMuted;
        label = 'Terminé';
        break;
      default:
        color = AppColors.danger;
        label = 'Erreur';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
