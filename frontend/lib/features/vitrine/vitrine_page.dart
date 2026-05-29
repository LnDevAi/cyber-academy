import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class VitrinePage extends StatelessWidget {
  const VitrinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _NavBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: const [
                  _HeroSection(),
                  _ChiffresSection(),
                  _BlocsSection(),
                  _TARGUISection(),
                  _CyberRangeSection(),
                  _PartenairesSection(),
                  _TemoignagesSection(),
                  _CTAFinalSection(),
                  _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.cyberGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('CA',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Text('CYBER ACADEMY',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5)),
              const SizedBox(width: 4),
              Text('E-DEFENCE',
                  style: GoogleFonts.inter(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w500,
                      fontSize: 11)),
            ],
          ),
          const Spacer(),
          // Nav links
          _NavLink('Catalogue', () => context.go('/catalogue')),
          const SizedBox(width: 24),
          _NavLink('À propos', () {}),
          const SizedBox(width: 24),
          _NavLink('Contact', () {}),
          const SizedBox(width: 32),
          OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Connexion'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("S'inscrire"),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(80, 100, 80, 100),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0f172a), Color(0xFF0c1a2e), Color(0xFF0f172a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.accentCyan, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  'Plateforme #1 de cybersécurité en Afrique de l\'Ouest',
                  style: GoogleFonts.inter(
                      color: AppColors.accentCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Formez les Gardiens\nNumériques de l\'Afrique',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Cyber Academy E-DEFENCE est la première plateforme phygitale africaine de formation certifiante en cybersécurité. 10 certifications reconnues, Cyber Range virtualisé, tuteur IA TARGUI, badges blockchain.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 44),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Builder(builder: (ctx) => CyberButton(
                label: 'Voir le catalogue',
                onPressed: () => ctx.go('/catalogue'),
                icon: Icons.menu_book_outlined,
              )),
              const SizedBox(width: 16),
              Builder(builder: (ctx) => OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.flash_on, size: 18),
                label: const Text('Audit Flash gratuit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              )),
            ],
          ),
          const SizedBox(height: 60),
          // Partner logos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Partenaires: ',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 12),
              ...[
                'PECB', 'EC-Council', 'Cisco', 'Fortinet', '(ISC)²', 'CompTIA'
              ].map((p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(p,
                        style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChiffresSection extends StatelessWidget {
  const _ChiffresSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardWhite,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 80),
      child: Column(
        children: [
          _SectionHeader(
              title: 'Chiffres clés',
              subtitle: 'La référence cybersécurité en UEMOA'),
          const SizedBox(height: 40),
          Row(
            children: const [
              Expanded(
                child: StatCard(
                  icon: Icons.workspace_premium,
                  value: '10',
                  label: 'Certifications reconnues',
                  iconColor: AppColors.accentCyan,
                  trend: '+2 en 2026',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  icon: Icons.terminal,
                  value: '30+',
                  label: 'Labs Cyber Range',
                  iconColor: AppColors.accentBlue,
                  trend: 'k3s + Guacamole',
                  trendPositive: true,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  icon: Icons.handshake_outlined,
                  value: '7',
                  label: 'Partenaires internationaux',
                  iconColor: AppColors.warning,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  icon: Icons.phone_android,
                  value: 'Mobile',
                  label: 'Paiement Mobile Money',
                  iconColor: AppColors.success,
                  trend: 'Orange, Moov, Wave',
                  trendPositive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlocsSection extends StatelessWidget {
  const _BlocsSection();

  @override
  Widget build(BuildContext context) {
    const blocs = [
      _BlocData(
        code: 'A',
        label: 'Fondamentaux',
        color: AppColors.blocA,
        icon: Icons.security,
        description: 'Les bases de la cybersécurité et certifications ISO 27001',
        cours: ['A01 — Fondamentaux Cybersécurité', 'A02 — ISO 27001 Lead Implementer'],
      ),
      _BlocData(
        code: 'B',
        label: 'Gouvernance & Conformité',
        color: AppColors.blocB,
        icon: Icons.gavel,
        description: 'DPO, CISM, conformité CIL Burkina Faso et RGPD',
        cours: ['B01 — Data Protection Officer', 'B02 — CISM (ISACA)'],
      ),
      _BlocData(
        code: 'C',
        label: 'Sécurité Offensive',
        color: AppColors.blocC,
        icon: Icons.bug_report,
        description: 'Pentest, Ethical Hacking, CEH EC-Council',
        cours: ['C01 — Pentest & Ethical Hacking', 'C02 — CEH (EC-Council)'],
      ),
      _BlocData(
        code: 'D',
        label: 'Réseaux & Infrastructure',
        color: AppColors.blocD,
        icon: Icons.router,
        description: 'Sécurité réseaux, Fortinet NSE 4, Cisco',
        cours: ['D01 — Sécurité Réseaux', 'D02 — Fortinet NSE 4'],
      ),
      _BlocData(
        code: 'E',
        label: 'Forensic & Incident',
        color: AppColors.blocE,
        icon: Icons.find_in_page,
        description: 'Investigation numérique, CHFI, gestion d\'incidents',
        cours: ['E01 — Forensic Numérique', 'E02 — CHFI (EC-Council)'],
      ),
    ];

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 80),
      child: Column(
        children: [
          _SectionHeader(
            title: 'Les 5 blocs de compétences',
            subtitle:
                'Un parcours structuré du débutant à l\'expert en cybersécurité',
          ),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: blocs
                .map((b) => Expanded(child: _BlocCard(bloc: b)))
                .toList()
                .expand((w) => [w, const SizedBox(width: 16)])
                .toList()
              ..removeLast(),
          ),
        ],
      ),
    );
  }
}

class _BlocData {
  final String code;
  final String label;
  final Color color;
  final IconData icon;
  final String description;
  final List<String> cours;
  const _BlocData({
    required this.code,
    required this.label,
    required this.color,
    required this.icon,
    required this.description,
    required this.cours,
  });
}

class _BlocCard extends StatelessWidget {
  final _BlocData bloc;
  const _BlocCard({required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bloc.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(bloc.icon, color: bloc.color, size: 24),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bloc.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'BLOC ${bloc.code}',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            bloc.label,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            bloc.description,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          ...bloc.cours.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: bloc.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TARGUISection extends StatelessWidget {
  const _TARGUISection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 80),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                  ),
                  child: Text('TARGUI IA',
                      style: GoogleFonts.inter(
                          color: AppColors.accentCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Votre tuteur IA\n24h/24, 7j/7',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'TARGUI est votre assistant pédagogique IA spécialisé en cybersécurité. Il comprend vos parcours, vous guide dans les labs, explique les concepts complexes et vous aide à débloquer les situations difficiles.',
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeatureChip('Contexte de votre parcours'),
                    _FeatureChip('Explications techniques'),
                    _FeatureChip('Aide sur les labs'),
                    _FeatureChip('Exercices pratiques'),
                    _FeatureChip('Optimisé pour le français'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 80),
          // Chat mockup
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.cyberGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('T',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TARGUI',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          Text('Tuteur IA E-DEFENCE',
                              style: GoogleFonts.inter(
                                  color: AppColors.accentCyan, fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.success, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Messages
                  _ChatMockBubble(
                    isAI: true,
                    text: "Bonjour! Je suis TARGUI, votre tuteur en cybersécurité. Vous en êtes au module 3 du parcours Pentest. Comment puis-je vous aider?",
                  ),
                  const SizedBox(height: 12),
                  _ChatMockBubble(
                    isAI: false,
                    text: "Je suis bloqué sur le lab SQL Injection du module 3.",
                  ),
                  const SizedBox(height: 12),
                  _ChatMockBubble(
                    isAI: true,
                    text: "Pour l'injection SQL, commencez par tester avec: ' OR '1'='1. Ensuite essayez d'énumérer les tables avec UNION SELECT. Voulez-vous que je vous explique la technique UNION-based en détail?",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _ChatMockBubble extends StatelessWidget {
  final bool isAI;
  final String text;
  const _ChatMockBubble({required this.isAI, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAI ? const Color(0xFF0f172a) : AppColors.accentBlue,
          borderRadius: BorderRadius.circular(10),
          border: isAI
              ? Border.all(color: AppColors.accentCyan.withOpacity(0.2))
              : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 12, height: 1.4),
        ),
      ),
    );
  }
}

class _CyberRangeSection extends StatelessWidget {
  const _CyberRangeSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 80),
      child: Row(
        children: [
          // Terminal mockup
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0f172a),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1e293b)),
              ),
              child: Column(
                children: [
                  // Terminal header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1e293b),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(
                                color: Color(0xFFef4444), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(
                                color: Color(0xFFf59e0b), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(
                                color: Color(0xFF10b981), shape: BoxShape.circle)),
                        const SizedBox(width: 16),
                        Text('Cyber Range — Lab 03: SQLi Attack',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  // Terminal content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TermLine('root@cyberrange:~\$ nmap -sV 10.0.0.1', color: AppColors.accentCyan),
                        const SizedBox(height: 6),
                        _TermLine('Starting Nmap 7.94 ...'),
                        _TermLine('80/tcp   open  http     Apache 2.4.51'),
                        _TermLine('3306/tcp open  mysql    MySQL 5.7.39'),
                        _TermLine('443/tcp  open  ssl/http'),
                        const SizedBox(height: 10),
                        _TermLine("root@cyberrange:~\$ sqlmap -u 'http://target/login.php'", color: AppColors.accentCyan),
                        const SizedBox(height: 6),
                        _TermLine('[INFO] testing MySQL'),
                        _TermLine('[CRITICAL] injectable parameter found: id', color: AppColors.danger),
                        _TermLine('[SUCCESS] Extracted: users table (247 rows)', color: AppColors.success),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 80),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
                  ),
                  child: Text('CYBER RANGE',
                      style: GoogleFonts.inter(
                          color: AppColors.accentBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Entraînez-vous sur\ndes environnements réels',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notre Cyber Range propulsé par k3s et Apache Guacamole offre plus de 30 labs sur des environnements virtualisés identiques aux situations réelles. Aucune installation requise — 100% dans votre navigateur.',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 24),
                ...[
                  ('30+', 'Labs variés: pentest, forensic, réseaux'),
                  ('k3s', 'Infrastructure Kubernetes légère'),
                  ('100%', 'Dans le navigateur via Guacamole'),
                  ('3G', 'Optimisé pour connexions limitées'),
                ].map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(item.$1,
                                style: GoogleFonts.inter(
                                    color: AppColors.accentBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 12),
                          Text(item.$2,
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermLine extends StatelessWidget {
  final String text;
  final Color? color;
  const _TermLine(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sourceCodePro(
        color: color ?? const Color(0xFF94a3b8),
        fontSize: 12,
        height: 1.5,
      ),
    );
  }
}

class _PartenairesSection extends StatelessWidget {
  const _PartenairesSection();

  @override
  Widget build(BuildContext context) {
    const partners = [
      'PECB', 'Cisco', 'Fortinet', 'EC-Council', '(ISC)²', 'CompTIA', 'ISACA'
    ];

    return Container(
      color: AppColors.cardWhite,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
      child: Column(
        children: [
          Text(
            'Nos partenaires de certification',
            style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Certifications reconnues internationalement',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: partners
                .map((p) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textSecondary),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TemoignagesSection extends StatelessWidget {
  const _TemoignagesSection();

  @override
  Widget build(BuildContext context) {
    const temoignages = [
      _Temoignage(
        nom: 'Issouf Traoré',
        poste: 'Analyste SOC, Banque de l\'UEMOA',
        texte:
            'La formation Fondamentaux Cybersécurité + Pentest m\'a permis de décrocher mon poste en 4 mois. Les labs du Cyber Range sont identiques aux environnements qu\'on utilise en entreprise. TARGUI m\'a débloqué plus d\'une fois sur des concepts complexes.',
        photo: 'IT',
        note: 5,
      ),
      _Temoignage(
        nom: 'Aminata Coulibaly',
        poste: 'DPO, Ministère de la Santé du Mali',
        texte:
            'La certification DPO adaptée au contexte CIL Burkina Faso et RGPD était exactement ce dont j\'avais besoin. La formation en ligne me permettait de suivre à mon rythme, et le paiement en 3x Orange Money a rendu l\'accès possible.',
        photo: 'AC',
        note: 5,
      ),
      _Temoignage(
        nom: 'Moussa Ouédraogo',
        poste: 'Pentester indépendant, Ouagadougou',
        texte:
            'Le badge blockchain sur ma certification CEH m\'a ouvert des portes à l\'international. Les recruteurs vérifient l\'authenticité immédiatement. Le Cyber Range avec 20 labs EC-Council était parfaitement intégré au contenu théorique.',
        photo: 'MO',
        note: 5,
      ),
    ];

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 80),
      child: Column(
        children: [
          _SectionHeader(
            title: 'Ils ont réussi avec E-DEFENCE',
            subtitle: 'Témoignages de nos apprenants certifiés',
          ),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: temoignages
                .map((t) => Expanded(child: _TemoignageCard(t: t)))
                .toList()
                .expand((w) => [w, const SizedBox(width: 20)])
                .toList()
              ..removeLast(),
          ),
        ],
      ),
    );
  }
}

class _Temoignage {
  final String nom;
  final String poste;
  final String texte;
  final String photo;
  final int note;
  const _Temoignage({
    required this.nom,
    required this.poste,
    required this.texte,
    required this.photo,
    required this.note,
  });
}

class _TemoignageCard extends StatelessWidget {
  final _Temoignage t;
  const _TemoignageCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              t.note,
              (_) => const Icon(Icons.star, color: AppColors.warning, size: 16),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '"${t.texte}"',
            style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.cyberGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(t.photo,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.nom,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(t.poste,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CTAFinalSection extends StatelessWidget {
  const _CTAFinalSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 80),
      child: Column(
        children: [
          Text(
            'Prêt à devenir gardien numérique?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Rejoignez des milliers d\'apprenants africains formés en cybersécurité.',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 36),
          Builder(
            builder: (ctx) => CyberButton(
              label: 'Commencer mon parcours cybersécurité',
              onPressed: () => ctx.go('/register'),
              icon: Icons.rocket_launch_outlined,
              width: 400,
            ),
          ),
          const SizedBox(height: 16),
          Builder(builder: (ctx) => TextButton(
            onPressed: () => ctx.go('/catalogue'),
            child: Text(
              'Voir le catalogue sans s\'inscrire →',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),
          )),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0c1a2e),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 80),
      child: Row(
        children: [
          Text(
            '© 2026 Cyber Academy E-DEFENCE. Tous droits réservés.',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
          const Spacer(),
          Text(
            'Conforme CIL Burkina Faso · Données hébergées en Afrique',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 16, color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}
