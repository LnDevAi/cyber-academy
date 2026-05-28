import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              _buildLogo(),
              const SizedBox(height: 48),
              _buildTitle(),
              const SizedBox(height: 32),
              if (authState.error != null) _buildErrorBanner(authState.error!),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    _buildForgotPassword(),
                    const SizedBox(height: 32),
                    CyberButton(
                      label: 'Se connecter',
                      onPressed: authState.isLoading ? null : _login,
                      isLoading: authState.isLoading,
                      width: double.infinity,
                      icon: Icons.login_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildRegisterLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.cyberGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'CYBER ACADEMY',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'E-DÉFENCE',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.accent,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Bienvenue !',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connectez-vous pour accéder à votre\nespace de formation cybersécurité',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(authProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: const InputDecoration(
        labelText: 'Adresse e-mail',
        hintText: 'vous@exemple.com',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'L\'adresse e-mail est requise';
        if (!v.contains('@')) return 'Adresse e-mail invalide';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _login(),
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Le mot de passe est requis';
        if (v.length < 6) return 'Minimum 6 caractères';
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réinitialisation par e-mail — fonctionnalité à venir'),
            ),
          );
        },
        child: const Text('Mot de passe oublié ?'),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ? ',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => context.go('/register'),
          child: Text(
            "S'inscrire",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}
