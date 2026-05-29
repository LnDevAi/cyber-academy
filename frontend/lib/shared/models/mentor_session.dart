class MentorSession {
  final String id;
  final String mentorId;
  final String apprenantId;
  final String enrollmentId;
  final String sujet;
  final DateTime dateHeure;
  final int dureeeMinutes;
  final String statut; // planifie | confirme | en_cours | termine | annule
  final String? visioUrl;
  final String? notes;
  final String? mentorNom;
  final String? apprenantNom;

  const MentorSession({
    required this.id,
    required this.mentorId,
    required this.apprenantId,
    required this.enrollmentId,
    required this.sujet,
    required this.dateHeure,
    required this.dureeeMinutes,
    required this.statut,
    this.visioUrl,
    this.notes,
    this.mentorNom,
    this.apprenantNom,
  });

  factory MentorSession.fromJson(Map<String, dynamic> json) {
    return MentorSession(
      id: json['id']?.toString() ?? '',
      mentorId: json['mentor_id']?.toString() ?? '',
      apprenantId: json['apprenant_id']?.toString() ?? '',
      enrollmentId: json['enrollment_id']?.toString() ?? '',
      sujet: json['sujet'] ?? '',
      dateHeure: json['date_heure'] != null
          ? DateTime.parse(json['date_heure'])
          : DateTime.now(),
      dureeeMinutes: json['duree_minutes'] ?? 60,
      statut: json['statut'] ?? 'planifie',
      visioUrl: json['visio_url'],
      notes: json['notes'],
      mentorNom: json['mentor_nom'],
      apprenantNom: json['apprenant_nom'],
    );
  }

  bool get isAVenir => statut == 'planifie' || statut == 'confirme';
  bool get isTermine => statut == 'termine';

  String get statutLabel {
    switch (statut) {
      case 'planifie': return 'Planifié';
      case 'confirme': return 'Confirmé';
      case 'en_cours': return 'En cours';
      case 'termine': return 'Terminé';
      case 'annule': return 'Annulé';
      default: return statut;
    }
  }
}

class Mentor {
  final String id;
  final String nomComplet;
  final String email;
  final String specialite;
  final String bio;
  final List<String> certifications;
  final double note;
  final int nombreSessions;
  final String? avatarUrl;

  const Mentor({
    required this.id,
    required this.nomComplet,
    required this.email,
    required this.specialite,
    required this.bio,
    required this.certifications,
    required this.note,
    required this.nombreSessions,
    this.avatarUrl,
  });

  factory Mentor.fromJson(Map<String, dynamic> json) {
    return Mentor(
      id: json['id']?.toString() ?? '',
      nomComplet: json['nom_complet'] ?? '',
      email: json['email'] ?? '',
      specialite: json['specialite'] ?? '',
      bio: json['bio'] ?? '',
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : [],
      note: (json['note'] ?? 0).toDouble(),
      nombreSessions: json['nombre_sessions'] ?? 0,
      avatarUrl: json['avatar_url'],
    );
  }

  String get initials {
    final parts = nomComplet.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nomComplet.isNotEmpty ? nomComplet[0].toUpperCase() : 'M';
  }
}

class Livrable {
  final String id;
  final String enrollmentId;
  final String apprenantNom;
  final String titre;
  final String moduleNom;
  final DateTime dateDepot;
  final String? note;
  final String statut; // en_attente | corrige
  final String? fileUrl;

  const Livrable({
    required this.id,
    required this.enrollmentId,
    required this.apprenantNom,
    required this.titre,
    required this.moduleNom,
    required this.dateDepot,
    this.note,
    required this.statut,
    this.fileUrl,
  });

  factory Livrable.fromJson(Map<String, dynamic> json) {
    return Livrable(
      id: json['id']?.toString() ?? '',
      enrollmentId: json['enrollment_id']?.toString() ?? '',
      apprenantNom: json['apprenant_nom'] ?? '',
      titre: json['titre'] ?? '',
      moduleNom: json['module_nom'] ?? '',
      dateDepot: json['date_depot'] != null
          ? DateTime.parse(json['date_depot'])
          : DateTime.now(),
      note: json['note']?.toString(),
      statut: json['statut'] ?? 'en_attente',
      fileUrl: json['file_url'],
    );
  }
}
