class Payment {
  final String id;
  final String enrollmentId;
  final String userId;
  final double montant;
  final String devise; // XOF, EUR
  final String methode; // orange_money, moov_money, wave, stripe
  final String statut; // en_attente, confirme, echoue, rembourse
  final int echeances;
  final int echeanceActuelle;
  final String? transactionId;
  final String? telephone;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  const Payment({
    required this.id,
    required this.enrollmentId,
    required this.userId,
    required this.montant,
    required this.devise,
    required this.methode,
    required this.statut,
    required this.echeances,
    required this.echeanceActuelle,
    this.transactionId,
    this.telephone,
    required this.createdAt,
    this.confirmedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      enrollmentId: json['enrollment_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      devise: json['devise'] ?? 'XOF',
      methode: json['methode'] ?? '',
      statut: json['statut'] ?? 'en_attente',
      echeances: json['echeances'] ?? 1,
      echeanceActuelle: json['echeance_actuelle'] ?? 1,
      transactionId: json['transaction_id'],
      telephone: json['telephone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'enrollment_id': enrollmentId,
    'montant': montant,
    'devise': devise,
    'methode': methode,
    'statut': statut,
    'echeances': echeances,
    'echeance_actuelle': echeanceActuelle,
    'transaction_id': transactionId,
    'telephone': telephone,
    'created_at': createdAt.toIso8601String(),
    'confirmed_at': confirmedAt?.toIso8601String(),
  };

  bool get isConfirme => statut == 'confirme';
  bool get isEnAttente => statut == 'en_attente';
  bool get isEchoue => statut == 'echoue';

  String get methodeLabel {
    switch (methode) {
      case 'orange_money': return 'Orange Money';
      case 'moov_money': return 'Moov Money';
      case 'wave': return 'Wave';
      case 'stripe': return 'Carte bancaire';
      default: return methode;
    }
  }

  String get statutLabel {
    switch (statut) {
      case 'confirme': return 'Confirmé';
      case 'en_attente': return 'En attente';
      case 'echoue': return 'Échoué';
      case 'rembourse': return 'Remboursé';
      default: return statut;
    }
  }
}
