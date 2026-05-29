class CyberRangeSession {
  final String id;
  final String labId;
  final String enrollmentId;
  final String userId;
  final String statut; // demarrage | actif | termine | erreur
  final String? guacamoleUrl;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? dureeSecondes;
  final Map<String, dynamic>? resourceUsage;

  const CyberRangeSession({
    required this.id,
    required this.labId,
    required this.enrollmentId,
    required this.userId,
    required this.statut,
    this.guacamoleUrl,
    this.startedAt,
    this.endedAt,
    this.dureeSecondes,
    this.resourceUsage,
  });

  factory CyberRangeSession.fromJson(Map<String, dynamic> json) {
    return CyberRangeSession(
      id: json['id']?.toString() ?? '',
      labId: json['lab_id']?.toString() ?? '',
      enrollmentId: json['enrollment_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      statut: json['statut'] ?? 'demarrage',
      guacamoleUrl: json['guacamole_url'],
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      dureeSecondes: json['duree_secondes'],
      resourceUsage: json['resource_usage'],
    );
  }

  bool get isActive => statut == 'actif';
  bool get isDemarrage => statut == 'demarrage';
  bool get isTermine => statut == 'termine';

  String get statutLabel {
    switch (statut) {
      case 'demarrage': return 'Démarrage...';
      case 'actif': return 'Connecté';
      case 'termine': return 'Terminé';
      case 'erreur': return 'Erreur';
      default: return statut;
    }
  }
}

class Lab {
  final String id;
  final String courseCode;
  final String titre;
  final String description;
  final int ordre;
  final int difficulte; // 1-5
  final int dureeMinutes;
  final String statut; // disponible | en_cours | termine | verrouille
  final List<String> objectifs;
  final List<String> hints;
  final String? completedAt;

  const Lab({
    required this.id,
    required this.courseCode,
    required this.titre,
    required this.description,
    required this.ordre,
    required this.difficulte,
    required this.dureeMinutes,
    required this.statut,
    this.objectifs = const [],
    this.hints = const [],
    this.completedAt,
  });

  factory Lab.fromJson(Map<String, dynamic> json) {
    return Lab(
      id: json['id']?.toString() ?? '',
      courseCode: json['course_code'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      ordre: json['ordre'] ?? 0,
      difficulte: json['difficulte'] ?? 1,
      dureeMinutes: json['duree_minutes'] ?? 60,
      statut: json['statut'] ?? 'disponible',
      objectifs: json['objectifs'] != null ? List<String>.from(json['objectifs']) : [],
      hints: json['hints'] != null ? List<String>.from(json['hints']) : [],
      completedAt: json['completed_at'],
    );
  }

  bool get isDisponible => statut == 'disponible';
  bool get isTermine => statut == 'termine';
  bool get isEnCours => statut == 'en_cours';
  bool get isVerrouille => statut == 'verrouille';

  String get statutLabel {
    switch (statut) {
      case 'disponible': return 'Disponible';
      case 'en_cours': return 'En cours';
      case 'termine': return 'Terminé';
      case 'verrouille': return 'Verrouillé';
      default: return statut;
    }
  }
}
