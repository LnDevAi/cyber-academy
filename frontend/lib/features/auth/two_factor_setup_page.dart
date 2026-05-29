import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import 'auth_provider.dart';

class TwoFactorSetupPage extends ConsumerStatefulWidget {
  const TwoFactorSetupPage({super.key});

  @override
  ConsumerState<TwoFactorSetupPage> createState() => _TwoFactorSetupPageState();
}

class _TwoFactorSetupPageState extends ConsumerState<TwoFactorSetupPage> {
  Map<String, dynamic>? _setupData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSetup();
  }

  Future<void> _loadSetup() async {
    final data = await ref.read(authProvider.notifier).setup2FA();
    if (mounted) {
      setState(() {
        _setupData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuration 2FA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _isLoading
              ? const CircularProgressIndicator()
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final qrData = _setupData?['qr_url'] ?? 'https://cyber-academy.edefence.io';
    final secret = _setupData?['secret'] ?? '****';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security, color: AppColors.accentCyan, size: 48),
          const SizedBox(height: 16),
          Text(
            'Activer l\'authentification à deux facteurs',
            style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Scannez ce QR code avec une application d\'authentification (Google Authenticator, Authy) pour sécuriser votre compte.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clé secrète (si QR non disponible)',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  secret,
                  style: GoogleFonts.sourceCodePro(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          CyberButton(
            label: 'Vérifier le code',
            onPressed: () => context.go('/2fa-verify'),
            width: double.infinity,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go('/dashboard'),
              child: Text(
                'Configurer plus tard',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TwoFactorVerifyPage extends ConsumerStatefulWidget {
  const TwoFactorVerifyPage({super.key});

  @override
  ConsumerState<TwoFactorVerifyPage> createState() => _TwoFactorVerifyPageState();
}

class _TwoFactorVerifyPageState extends ConsumerState<TwoFactorVerifyPage> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length < 6) return;
    setState(() => _isLoading = true);
    try {
      final ok = await ref.read(authProvider.notifier).verify2FA(_codeCtrl.text);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('2FA activé avec succès!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code incorrect. Réessayez.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vérification 2FA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/2fa-setup'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outlined, color: AppColors.accentCyan, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Code de vérification',
                  style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez le code à 6 chiffres affiché dans votre application d\'authentification.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 8),
                  decoration: const InputDecoration(
                    hintText: '000000',
                    counterText: '',
                  ),
                  onChanged: (v) {
                    if (v.length == 6) _verify();
                  },
                ),
                const SizedBox(height: 28),
                CyberButton(
                  label: 'Vérifier',
                  onPressed: _verify,
                  isLoading: _isLoading,
                  width: double.infinity,
                  icon: Icons.verified_user_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
