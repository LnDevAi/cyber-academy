import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class PaiementConfirmationPage extends StatefulWidget {
  final bool success;
  final String message;

  const PaiementConfirmationPage({
    super.key,
    required this.success,
    this.message = '',
  });

  @override
  State<PaiementConfirmationPage> createState() =>
      _PaiementConfirmationPageState();
}

class _PaiementConfirmationPageState extends State<PaiementConfirmationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: widget.success
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.danger.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.success
                              ? Icons.check_circle
                              : Icons.error_outline,
                          size: 56,
                          color: widget.success
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      widget.success
                          ? 'Paiement confirmé!'
                          : 'Paiement échoué',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.success
                          ? 'Votre parcours est maintenant activé. Bonne formation!'
                          : widget.message.isNotEmpty
                              ? widget.message
                              : 'Une erreur s\'est produite lors du paiement. Veuillez réessayer.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (widget.success) ...[
                      const SizedBox(height: 32),
                      // Summary box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            _ConfirmItem(
                              icon: Icons.check,
                              text: 'Accès immédiat à tous les modules',
                            ),
                            _ConfirmItem(
                              icon: Icons.check,
                              text: 'Labs Cyber Range activés',
                            ),
                            _ConfirmItem(
                              icon: Icons.check,
                              text: 'TARGUI IA disponible 24h/24',
                            ),
                            _ConfirmItem(
                              icon: Icons.check,
                              text: 'Badge blockchain à l\'obtention',
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (widget.success)
                      CyberButton(
                        label: 'Accéder à mon parcours',
                        onPressed: () => context.go('/dashboard'),
                        width: double.infinity,
                        icon: Icons.school_outlined,
                      )
                    else
                      Column(
                        children: [
                          CyberButton(
                            label: 'Réessayer le paiement',
                            onPressed: () => context.go('/dashboard'),
                            width: double.infinity,
                            icon: Icons.refresh,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.go('/dashboard'),
                            child: Text(
                              'Retourner au tableau de bord',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    if (widget.success)
                      TextButton(
                        onPressed: () => context.go('/catalogue'),
                        child: Text(
                          'Explorer d\'autres formations',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConfirmItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
