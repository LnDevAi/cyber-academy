class User {
  final String id;
  final String nomComplet;
  final String email;
  final String telephone;
  final String profil;
  final String role;
  final bool is2FAEnabled;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.nomComplet,
    required this.email,
    required this.telephone,
    required this.profil,
    required this.role,
    required this.is2FAEnabled,
    this.avatarUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      nomComplet: json['nom_complet'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      profil: json['profil'] ?? '',
      role: json['role'] ?? 'apprenant',
      is2FAEnabled: json['is_2fa_enabled'] ?? false,
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom_complet': nomComplet,
    'email': email,
    'telephone': telephone,
    'profil': profil,
    'role': role,
    'is_2fa_enabled': is2FAEnabled,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };

  String get prenom => nomComplet.split(' ').first;

  String get initials {
    final parts = nomComplet.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : 'U';
  }
}
