import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/enrollments_api.dart';
import '../../shared/models/enrollment.dart';
import '../../shared/models/course.dart';
import '../../shared/widgets/payment_method_tile.dart';
import 'payment_provider.dart';

final enrollmentForPaymentProvider =
    FutureProvider.autoDispose.family<Enrollment, String>((ref, id) async {
  final api = ref.read(enrollmentsApiProvider);
  try {
    final data = await api.getEnrollment(id);
    return Enrollment.fromJson(data);
  } catch (_) {
    return Enrollment(
      id: id,
      userId: '1',
      courseCode: 'C01-PEN',
      courseTitre: 'Pentest & Ethical Hacking',
      statut: 'actif',
      progression: 0,
      dateDebut: DateTime.now(),
      course: Course.fromJson(CourseData.sampleCourses
          .firstWhere((c) => c['code'] == 'C01-PEN')),
    );
  }
});

class PaiementPage extends ConsumerStatefulWidget {
  final String enrollmentId;
  const PaiementPage({super.key, required this.enrollmentId});

  @override
  ConsumerState<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends ConsumerState<PaiementPage> {
  String _selectedMethod = 'orange_money';
  int _echeances = 1;
  final _telephoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _telephoneCtrl.dispose();
    super.dispose();
  }

  bool get _isMobileMoney => _selectedMethod != 'stripe';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(paymentProvider(widget.enrollmentId).notifier);
    bool success;

    if (_isMobileMoney) {
      success = await notifier.initiateMobileMoney(
        method: _selectedMethod,
        telephone: _telephoneCtrl.text.trim(),
        echeances: _echeances,
      );
    } else {
      success = await notifier.initiateStripe();
    }

    if (mounted) {
      if (success) {
        context.go('/paiement/confirmation?success=true');
      } else {
        final error = ref.read(paymentProvider(widget.enrollmentId)).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Erreur de paiement'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentAsync =
        ref.watch(enrollmentForPaymentProvider(widget.enrollmentId));
    final paymentState = ref.watch(paymentProvider(widget.enrollmentId));
    final formatter = NumberFormat('#,###', 'fr_FR');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'Paiement',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, size: 12, color: Colors.white54),
                      const SizedBox(width: 5),
                      Text('SSL sécurisé · CinetPay · Stripe',
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: enrollmentAsync.when(
              data: (enrollment) {
                final price = enrollment.course?.prix ?? 150000.0;
                final montantEcheance = (price / _echeances).round();

                return Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment methods column
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Choisir un moyen de paiement',
                                  style: GoogleFonts.inter(
                                      fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 20),
                              ...PaymentMethod.methods.map((m) =>
                                  PaymentMethodTile(
                                    methodKey: m['key'] as String,
                                    nom: m['nom'] as String,
                                    description: m['description'] as String,
                                    color: m['color'] as Color,
                                    icon: m['icon'] as IconData,
                                    isSelected: _selectedMethod == m['key'],
                                    isRecommande: m['isRecommande'] as bool,
                                    onSelect: () => setState(
                                        () => _selectedMethod = m['key'] as String),
                                  )),
                              // Phone number
                              if (_isMobileMoney) ...[
                                const SizedBox(height: 20),
                                Text('Numéro de téléphone',
                                    style: GoogleFonts.inter(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _telephoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    hintText: '+226 70 00 00 00',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                  validator: (v) {
                                    if (_isMobileMoney &&
                                        (v == null || v.isEmpty)) {
                                      return 'Numéro requis pour paiement mobile';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              // Installments
                              if (_isMobileMoney &&
                                  enrollment.course?.paiementEchelonne == true) ...[
                                const SizedBox(height: 24),
                                Text('Paiement échelonné',
                                    style: GoogleFonts.inter(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('Sans frais supplémentaires',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: AppColors.success)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [1, 2, 3].map((n) {
                                    final isSelected = _echeances == n;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _echeances = n),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 150),
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.accentCyan
                                                      .withOpacity(0.08)
                                                  : AppColors.cardWhite,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.accentCyan
                                                    : AppColors.border,
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  '${n}×',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                    color: isSelected
                                                        ? AppColors.accentCyan
                                                        : AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${formatter.format((price / n).round())} F',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const SizedBox(height: 20),
                              // CIL note
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.success.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_user_outlined,
                                        size: 16, color: AppColors.success),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Conforme CIL Burkina Faso. Données personnelles protégées. Paiement chiffré TLS 1.3.',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.success,
                                            height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Order summary sidebar
                      Container(
                        width: 300,
                        margin: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Récapitulatif',
                                style: GoogleFonts.inter(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    enrollment.courseTitre ?? enrollment.courseCode,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(enrollment.courseCode,
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.accentCyan,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total',
                                          style: GoogleFonts.inter(
                                              color: AppColors.textSecondary,
                                              fontSize: 13)),
                                      Text(
                                          '${formatter.format(price)} FCFA',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  if (_echeances > 1) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Aujourd\'hui',
                                            style: GoogleFonts.inter(
                                                color: AppColors.textSecondary,
                                                fontSize: 12)),
                                        Text(
                                          '${formatter.format(montantEcheance)} FCFA',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  CyberButton(
                                    label:
                                        'Payer ${formatter.format(_echeances > 1 ? montantEcheance : price.round())} FCFA',
                                    onPressed: _submit,
                                    isLoading: paymentState.isLoading,
                                    width: double.infinity,
                                    icon: Icons.payment,
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.lock,
                                            size: 12,
                                            color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text('Paiement 100% sécurisé',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.textMuted)),
                                      ],
                                    ),
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
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Erreur de chargement')),
            ),
          ),
        ],
      ),
    );
  }
}
