import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation'),
        ),
      );
      return;
    }
    final success = await ref.read(authProvider.notifier).register(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      passwordConfirm: _confirmCtrl.text,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 32),
              if (authState.error != null) _buildErrorBanner(authState.error!),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildUsernameField(),
                    const SizedBox(height: 16),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildConfirmField(),
                    const SizedBox(height: 20),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 32),
                    CyberButton(
                      label: "Créer mon compte",
                      onPressed: authState.isLoading ? null : _register,
                      isLoading: authState.isLoading,
                      width: double.infinity,
                      icon: Icons.person_add_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLoginLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.cyberGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 20),
        Text(
          'Créer un compte',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rejoignez la communauté Cyber Academy\net commencez votre formation',
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
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
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

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameCtrl,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: const InputDecoration(
        labelText: "Nom d'utilisateur",
        hintText: 'cyber_warrior',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Le nom d'utilisateur est requis";
        if (v.length < 3) return 'Minimum 3 caractères';
        if (v.length > 30) return 'Maximum 30 caractères';
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
          return 'Lettres, chiffres et _ uniquement';
        }
        return null;
      },
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
        if (v == null || v.isEmpty) return "L'adresse e-mail est requise";
        if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) {
          return 'Adresse e-mail invalide';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
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
        if (v.length < 8) return 'Minimum 8 caractères';
        return null;
      },
    );
  }

  Widget _buildConfirmField() {
    return TextFormField(
      controller: _confirmCtrl,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _register(),
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Confirmer le mot de passe',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'La confirmation est requise';
        if (v != _passwordCtrl.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
          activeColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                text: "J'accepte les ",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: "conditions d'utilisation",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' et la '),
                  TextSpan(
                    text: 'politique de confidentialité',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Text(
            'Se connecter',
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
