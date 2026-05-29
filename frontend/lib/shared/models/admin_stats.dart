class AdminStats {
  final int inscriptionsAujourdhui;
  final int inscriptionsSemaine;
  final int inscriptionsMois;
  final double revenusMois;
  final int sessionsRangeActives;
  final double tauxCompletion;
  final int utilisateursTotal;
  final int coursTotal;
  final int badgesEmis;

  const AdminStats({
    required this.inscriptionsAujourdhui,
    required this.inscriptionsSemaine,
    required this.inscriptionsMois,
    required this.revenusMois,
    required this.sessionsRangeActives,
    required this.tauxCompletion,
    required this.utilisateursTotal,
    required this.coursTotal,
    required this.badgesEmis,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      inscriptionsAujourdhui: json['inscriptions_aujourdhui'] ?? 0,
      inscriptionsSemaine: json['inscriptions_semaine'] ?? 0,
      inscriptionsMois: json['inscriptions_mois'] ?? 0,
      revenusMois: (json['revenus_mois'] ?? 0).toDouble(),
      sessionsRangeActives: json['sessions_range_actives'] ?? 0,
      tauxCompletion: (json['taux_completion'] ?? 0).toDouble(),
      utilisateursTotal: json['utilisateurs_total'] ?? 0,
      coursTotal: json['cours_total'] ?? 0,
      badgesEmis: json['badges_emis'] ?? 0,
    );
  }

  static AdminStats get sample => const AdminStats(
    inscriptionsAujourdhui: 12,
    inscriptionsSemaine: 87,
    inscriptionsMois: 342,
    revenusMois: 25840000,
    sessionsRangeActives: 8,
    tauxCompletion: 67.4,
    utilisateursTotal: 1247,
    coursTotal: 10,
    badgesEmis: 893,
  );
}

class B2BCompany {
  final String id;
  final String nomEntreprise;
  final String secteur;
  final String planAbonnement;
  final int seatsTotal;
  final int seatsUtilises;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double montantContrat;
  final List<B2BEmployee> employes;

  const B2BCompany({
    required this.id,
    required this.nomEntreprise,
    required this.secteur,
    required this.planAbonnement,
    required this.seatsTotal,
    required this.seatsUtilises,
    required this.dateDebut,
    required this.dateFin,
    required this.montantContrat,
    this.employes = const [],
  });

  factory B2BCompany.fromJson(Map<String, dynamic> json) {
    return B2BCompany(
      id: json['id']?.toString() ?? '',
      nomEntreprise: json['nom_entreprise'] ?? '',
      secteur: json['secteur'] ?? '',
      planAbonnement: json['plan_abonnement'] ?? 'standard',
      seatsTotal: json['seats_total'] ?? 0,
      seatsUtilises: json['seats_utilises'] ?? 0,
      dateDebut: json['date_debut'] != null
          ? DateTime.parse(json['date_debut'])
          : DateTime.now(),
      dateFin: json['date_fin'] != null
          ? DateTime.parse(json['date_fin'])
          : DateTime.now().add(const Duration(days: 365)),
      montantContrat: (json['montant_contrat'] ?? 0).toDouble(),
      employes: json['employes'] != null
          ? (json['employes'] as List).map((e) => B2BEmployee.fromJson(e)).toList()
          : [],
    );
  }

  int get seatsDisponibles => seatsTotal - seatsUtilises;
}

class B2BEmployee {
  final String id;
  final String nomComplet;
  final String email;
  final String? courseCode;
  final String? courseTitre;
  final double progression;
  final int badgesObtenus;
  final DateTime? derniereConnexion;

  const B2BEmployee({
    required this.id,
    required this.nomComplet,
    required this.email,
    this.courseCode,
    this.courseTitre,
    required this.progression,
    required this.badgesObtenus,
    this.derniereConnexion,
  });

  factory B2BEmployee.fromJson(Map<String, dynamic> json) {
    return B2BEmployee(
      id: json['id']?.toString() ?? '',
      nomComplet: json['nom_complet'] ?? '',
      email: json['email'] ?? '',
      courseCode: json['course_code'],
      courseTitre: json['course_titre'],
      progression: (json['progression'] ?? 0).toDouble(),
      badgesObtenus: json['badges_obtenus'] ?? 0,
      derniereConnexion: json['derniere_connexion'] != null
          ? DateTime.parse(json['derniere_connexion'])
          : null,
    );
  }
}

class Facture {
  final String id;
  final String companyId;
  final double montant;
  final String statut; // payee | en_attente | en_retard
  final DateTime dateEmission;
  final DateTime? datePaiement;
  final String? fileUrl;

  const Facture({
    required this.id,
    required this.companyId,
    required this.montant,
    required this.statut,
    required this.dateEmission,
    this.datePaiement,
    this.fileUrl,
  });

  factory Facture.fromJson(Map<String, dynamic> json) {
    return Facture(
      id: json['id']?.toString() ?? '',
      companyId: json['company_id']?.toString() ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      statut: json['statut'] ?? 'en_attente',
      dateEmission: json['date_emission'] != null
          ? DateTime.parse(json['date_emission'])
          : DateTime.now(),
      datePaiement: json['date_paiement'] != null
          ? DateTime.parse(json['date_paiement'])
          : null,
      fileUrl: json['file_url'],
    );
  }
}
