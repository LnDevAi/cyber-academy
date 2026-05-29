class Badge {
  final String id;
  final String userId;
  final String courseCode;
  final String courseTitre;
  final String imageUrl;
  final DateTime dateEmission;
  final String? blockchainTxHash;
  final String? blockchainVerifyUrl;
  final bool blockchainVerifie;
  final String partenaireCode;
  final String partenaireLogo;
  final int heuresCertifiees;

  const Badge({
    required this.id,
    required this.userId,
    required this.courseCode,
    required this.courseTitre,
    required this.imageUrl,
    required this.dateEmission,
    this.blockchainTxHash,
    this.blockchainVerifyUrl,
    this.blockchainVerifie = false,
    required this.partenaireCode,
    required this.partenaireLogo,
    required this.heuresCertifiees,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      courseCode: json['course_code'] ?? '',
      courseTitre: json['course_titre'] ?? '',
      imageUrl: json['image_url'] ?? '',
      dateEmission: json['date_emission'] != null
          ? DateTime.parse(json['date_emission'])
          : DateTime.now(),
      blockchainTxHash: json['blockchain_tx_hash'],
      blockchainVerifyUrl: json['blockchain_verify_url'],
      blockchainVerifie: json['blockchain_verifie'] ?? false,
      partenaireCode: json['partenaire_code'] ?? '',
      partenaireLogo: json['partenaire_logo'] ?? '',
      heuresCertifiees: json['heures_certifiees'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'course_code': courseCode,
    'course_titre': courseTitre,
    'image_url': imageUrl,
    'date_emission': dateEmission.toIso8601String(),
    'blockchain_tx_hash': blockchainTxHash,
    'blockchain_verify_url': blockchainVerifyUrl,
    'blockchain_verifie': blockchainVerifie,
    'partenaire_code': partenaireCode,
    'partenaire_logo': partenaireLogo,
    'heures_certifiees': heuresCertifiees,
  };

  String get verificationUrl => blockchainVerifyUrl ?? 'https://verify.edefence.io/badge/$id';
}
