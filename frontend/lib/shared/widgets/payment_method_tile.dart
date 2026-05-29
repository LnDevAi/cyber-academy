import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class PaymentMethodTile extends StatelessWidget {
  final String methodKey;
  final String nom;
  final String description;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final bool isRecommande;
  final VoidCallback onSelect;

  const PaymentMethodTile({
    super.key,
    required this.methodKey,
    required this.nom,
    required this.description,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onSelect,
    this.isRecommande = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Logo icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        nom,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isRecommande) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommandé',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentCyan,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: methodKey,
              groupValue: isSelected ? methodKey : null,
              onChanged: (_) => onSelect(),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

// Payment method data
class PaymentMethod {
  static const List<Map<String, dynamic>> methods = [
    {
      'key': 'orange_money',
      'nom': 'Orange Money',
      'description': 'Paiement instantané via Orange Money (UEMOA)',
      'color': Color(0xFFFF6200),
      'icon': Icons.phone_android,
      'isRecommande': true,
    },
    {
      'key': 'moov_money',
      'nom': 'Moov Money',
      'description': 'Paiement via Moov Money / Flooz',
      'color': Color(0xFF0066CC),
      'icon': Icons.phone_android,
      'isRecommande': false,
    },
    {
      'key': 'wave',
      'nom': 'Wave',
      'description': 'Paiement rapide avec Wave (0% frais)',
      'color': Color(0xFF009BDE),
      'icon': Icons.waves,
      'isRecommande': false,
    },
    {
      'key': 'stripe',
      'nom': 'Carte bancaire',
      'description': 'Visa, Mastercard — Paiement sécurisé par Stripe',
      'color': Color(0xFF6772E5),
      'icon': Icons.credit_card,
      'isRecommande': false,
    },
  ];
}
