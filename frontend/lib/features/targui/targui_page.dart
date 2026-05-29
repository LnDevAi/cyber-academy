import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/cyber_sidebar.dart';
import '../../shared/widgets/targui_bubble.dart';
import 'targui_provider.dart';

class TARGUIPage extends ConsumerStatefulWidget {
  const TARGUIPage({super.key});

  @override
  ConsumerState<TARGUIPage> createState() => _TARGUIPageState();
}

class _TARGUIPageState extends ConsumerState<TARGUIPage> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _quickSuggestions = [
    'Explique-moi ce concept',
    'Donne-moi un exercice pratique',
    'Je suis bloqué sur ce lab',
    'Comment se préparer à l\'examen?',
    'Quelle est la différence entre XSS et CSRF?',
  ];

  @override
  void initState() {
    super.initState();
    // Create initial session if none
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(targuiProvider);
      if (state.activeSessionId == null) {
        ref.read(targuiProvider.notifier).newSession();
      }
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    _messageCtrl.clear();
    await ref.read(targuiProvider.notifier).sendMessage(content);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final targuiState = ref.watch(targuiProvider);

    // Auto-scroll when messages change
    ref.listen(targuiProvider.select((s) => s.messages.length), (_, __) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const CyberSidebar(currentRoute: '/dashboard/targui'),
          // Session list
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Conversations',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            ref.read(targuiProvider.notifier).newSession(),
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: 'Nouvelle conversation',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                // Sessions list
                Expanded(
                  child: targuiState.sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_outlined,
                                  size: 32, color: AppColors.textMuted),
                              const SizedBox(height: 8),
                              Text(
                                'Aucune conversation',
                                style: GoogleFonts.inter(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: targuiState.sessions.length,
                          itemBuilder: (ctx, i) {
                            final session = targuiState.sessions[i];
                            final isActive =
                                session.id == targuiState.activeSessionId;
                            return ListTile(
                              selected: isActive,
                              selectedTileColor:
                                  AppColors.accentCyan.withOpacity(0.06),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.accentCyan.withOpacity(0.1)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                  color: isActive
                                      ? AppColors.accentCyan
                                      : AppColors.textMuted,
                                ),
                              ),
                              title: Text(
                                session.titre,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd/MM HH:mm')
                                    .format(session.updatedAt),
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: AppColors.textMuted),
                              ),
                              onTap: () => ref
                                  .read(targuiProvider.notifier)
                                  .selectSession(session.id),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 14, color: AppColors.textMuted),
                                onPressed: () => ref
                                    .read(targuiProvider.notifier)
                                    .deleteSession(session.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 24, minHeight: 24),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Chat area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.cardWhite,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.cyberGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text('T',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TARGUI — Tuteur IA E-DEFENCE',
                            style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            children: [
                              Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text(
                                'En ligne · Spécialisé cybersécurité UEMOA',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(targuiProvider.notifier).newSession(),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Nouvelle conversation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          textStyle: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: targuiState.messages.isEmpty
                      ? _WelcomeScreen(
                          onSuggestionTap: _sendMessage,
                          suggestions: _quickSuggestions,
                        )
                      : Container(
                          color: const Color(0xFF0f172a),
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(24),
                            itemCount: targuiState.messages.length,
                            itemBuilder: (ctx, i) => TARGUIBubble(
                                message: targuiState.messages[i]),
                          ),
                        ),
                ),
                // Input area
                Container(
                  color: const Color(0xFF1e293b),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Quick suggestions
                      if (targuiState.messages.isEmpty)
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _quickSuggestions
                                .map((s) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: OutlinedButton(
                                        onPressed: () => _sendMessage(s),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.accentCyan,
                                          side: BorderSide(
                                              color: AppColors.accentCyan
                                                  .withOpacity(0.4)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 0),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          textStyle: GoogleFonts.inter(
                                              fontSize: 12),
                                        ),
                                        child: Text(s),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageCtrl,
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 14),
                              maxLines: 3,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText:
                                    'Posez une question à TARGUI...',
                                hintStyle: GoogleFonts.inter(
                                    color: Colors.white38, fontSize: 13),
                                filled: true,
                                fillColor: const Color(0xFF0f172a),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Color(0xFF334155)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Color(0xFF334155)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.accentCyan, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.mic_outlined,
                                      color: Colors.white38, size: 18),
                                  onPressed: () {},
                                  tooltip: 'Note vocale',
                                ),
                              ),
                              onSubmitted: _sendMessage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.cyberGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentCyan.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: targuiState.isTyping
                                    ? null
                                    : () => _sendMessage(_messageCtrl.text),
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: targuiState.isTyping
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send,
                                          color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  final Function(String) onSuggestionTap;
  final List<String> suggestions;

  const _WelcomeScreen({
    required this.onSuggestionTap,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0f172a),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.cyberGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'T',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'TARGUI — Tuteur IA E-DEFENCE',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Posez-moi vos questions en cybersécurité.\nJe connais vos parcours et vos labs.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 36),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: suggestions
                  .map((s) => OutlinedButton(
                        onPressed: () => onSuggestionTap(s),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentCyan,
                          side: BorderSide(
                              color: AppColors.accentCyan.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          textStyle: GoogleFonts.inter(fontSize: 12),
                        ),
                        child: Text(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
