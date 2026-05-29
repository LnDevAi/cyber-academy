class Course {
  final String code;
  final String titre;
  final String description;
  final String bloc; // A, B, C, D, E
  final String type; // 'edefence' | 'international'
  final String niveau; // 'debutant' | 'intermediaire' | 'avance'
  final int dureeHeures;
  final double prix;
  final String partenaire;
  final String partenaireCode; // PECB, EC-Council, etc.
  final List<Module> modules;
  final List<String> prerequis;
  final List<String> publicCible;
  final String formatExamen;
  final String instructeurNom;
  final String instructeurBio;
  final int nombreLabs;
  final bool paiementEchelonne;

  const Course({
    required this.code,
    required this.titre,
    required this.description,
    required this.bloc,
    required this.type,
    required this.niveau,
    required this.dureeHeures,
    required this.prix,
    required this.partenaire,
    required this.partenaireCode,
    this.modules = const [],
    this.prerequis = const [],
    this.publicCible = const [],
    this.formatExamen = '',
    this.instructeurNom = '',
    this.instructeurBio = '',
    this.nombreLabs = 0,
    this.paiementEchelonne = true,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      code: json['code'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      bloc: json['bloc'] ?? 'A',
      type: json['type'] ?? 'edefence',
      niveau: json['niveau'] ?? 'debutant',
      dureeHeures: json['duree_heures'] ?? 0,
      prix: (json['prix'] ?? 0).toDouble(),
      partenaire: json['partenaire'] ?? '',
      partenaireCode: json['partenaire_code'] ?? '',
      modules: json['modules'] != null
          ? (json['modules'] as List).map((m) => Module.fromJson(m)).toList()
          : [],
      prerequis: json['prerequis'] != null
          ? List<String>.from(json['prerequis'])
          : [],
      publicCible: json['public_cible'] != null
          ? List<String>.from(json['public_cible'])
          : [],
      formatExamen: json['format_examen'] ?? '',
      instructeurNom: json['instructeur_nom'] ?? '',
      instructeurBio: json['instructeur_bio'] ?? '',
      nombreLabs: json['nombre_labs'] ?? 0,
      paiementEchelonne: json['paiement_echelonne'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'titre': titre,
    'description': description,
    'bloc': bloc,
    'type': type,
    'niveau': niveau,
    'duree_heures': dureeHeures,
    'prix': prix,
    'partenaire': partenaire,
    'partenaire_code': partenaireCode,
    'nombre_labs': nombreLabs,
    'paiement_echelonne': paiementEchelonne,
  };

  bool get isEDefence => type == 'edefence';
  bool get isInternational => type == 'international';

  String get blocLabel {
    switch (bloc) {
      case 'A': return 'Fondamentaux';
      case 'B': return 'Gouvernance & Conformité';
      case 'C': return 'Sécurité Offensive';
      case 'D': return 'Réseaux & Infrastructure';
      case 'E': return 'Forensic & Incident';
      default: return bloc;
    }
  }

  String get typeLabel => isEDefence ? 'E-Cert' : 'International';
}

class Module {
  final String id;
  final String titre;
  final String description;
  final int ordre;
  final int dureeHeures;
  final List<String> sousModules;

  const Module({
    required this.id,
    required this.titre,
    required this.description,
    required this.ordre,
    required this.dureeHeures,
    this.sousModules = const [],
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      ordre: json['ordre'] ?? 0,
      dureeHeures: json['duree_heures'] ?? 0,
      sousModules: json['sous_modules'] != null
          ? List<String>.from(json['sous_modules'])
          : [],
    );
  }
}

// The 10 E-DEFENCE certification courses
class CourseData {
  static const List<Map<String, dynamic>> sampleCourses = [
    // BLOC A — Fondamentaux
    {
      'code': 'A01-CYB',
      'titre': 'Fondamentaux de la Cybersécurité',
      'description': 'Introduction aux concepts essentiels de la cybersécurité, menaces, vulnérabilités et bonnes pratiques. Parcours d\'entrée pour tous les profils.',
      'bloc': 'A',
      'type': 'edefence',
      'niveau': 'debutant',
      'duree_heures': 40,
      'prix': 75000,
      'partenaire': 'E-DEFENCE Academy',
      'partenaire_code': 'EDEFENCE',
      'nombre_labs': 5,
      'paiement_echelonne': true,
    },
    {
      'code': 'A02-ISO',
      'titre': 'ISO 27001 Lead Implementer',
      'description': 'Certification internationale pour implémenter un SMSI conforme ISO 27001. Accrédité PECB.',
      'bloc': 'A',
      'type': 'international',
      'niveau': 'intermediaire',
      'duree_heures': 60,
      'prix': 350000,
      'partenaire': 'PECB',
      'partenaire_code': 'PECB',
      'nombre_labs': 8,
      'paiement_echelonne': true,
    },
    // BLOC B — Gouvernance
    {
      'code': 'B01-DPO',
      'titre': 'Data Protection Officer (DPO)',
      'description': 'Formation certifiante pour les responsables de la protection des données. Conformité CIL Burkina Faso + RGPD.',
      'bloc': 'B',
      'type': 'edefence',
      'niveau': 'intermediaire',
      'duree_heures': 50,
      'prix': 120000,
      'partenaire': 'E-DEFENCE Academy',
      'partenaire_code': 'EDEFENCE',
      'nombre_labs': 4,
      'paiement_echelonne': true,
    },
    {
      'code': 'B02-CISM',
      'titre': 'CISM — Certified Information Security Manager',
      'description': 'Certification de référence en gestion de la sécurité de l\'information pour managers. Accrédité ISACA.',
      'bloc': 'B',
      'type': 'international',
      'niveau': 'avance',
      'duree_heures': 80,
      'prix': 450000,
      'partenaire': 'ISACA',
      'partenaire_code': 'ISACA',
      'nombre_labs': 6,
      'paiement_echelonne': true,
    },
    // BLOC C — Offensif
    {
      'code': 'C01-PEN',
      'titre': 'Pentest & Ethical Hacking',
      'description': 'Tests d\'intrusion professionnels: reconnaissance, exploitation, post-exploitation, rapport. Labs sur environnements réels.',
      'bloc': 'C',
      'type': 'edefence',
      'niveau': 'intermediaire',
      'duree_heures': 70,
      'prix': 150000,
      'partenaire': 'E-DEFENCE Academy',
      'partenaire_code': 'EDEFENCE',
      'nombre_labs': 15,
      'paiement_echelonne': true,
    },
    {
      'code': 'C02-CEH',
      'titre': 'CEH — Certified Ethical Hacker',
      'description': 'Certification EC-Council de référence mondiale en ethical hacking. 20 domaines couverts.',
      'bloc': 'C',
      'type': 'international',
      'niveau': 'avance',
      'duree_heures': 90,
      'prix': 500000,
      'partenaire': 'EC-Council',
      'partenaire_code': 'ECCOUNCIL',
      'nombre_labs': 20,
      'paiement_echelonne': true,
    },
    // BLOC D — Réseaux
    {
      'code': 'D01-NET',
      'titre': 'Sécurité des Réseaux & Infrastructures',
      'description': 'Firewalls, VPN, segmentation, monitoring réseau. Configuration de Fortinet, Cisco. Environnements virtualisés.',
      'bloc': 'D',
      'type': 'edefence',
      'niveau': 'intermediaire',
      'duree_heures': 55,
      'prix': 130000,
      'partenaire': 'E-DEFENCE Academy',
      'partenaire_code': 'EDEFENCE',
      'nombre_labs': 10,
      'paiement_echelonne': true,
    },
    {
      'code': 'D02-FCP',
      'titre': 'Fortinet NSE 4 — FortiGate',
      'description': 'Certification Fortinet pour administrateurs FortiGate. Configuration, monitoring, VPN, SD-WAN.',
      'bloc': 'D',
      'type': 'international',
      'niveau': 'intermediaire',
      'duree_heures': 65,
      'prix': 280000,
      'partenaire': 'Fortinet',
      'partenaire_code': 'FORTINET',
      'nombre_labs': 12,
      'paiement_echelonne': true,
    },
    // BLOC E — Forensic
    {
      'code': 'E01-FOR',
      'titre': 'Forensic Numérique & Analyse d\'Incidents',
      'description': 'Investigation numérique, analyse de malwares, gestion des incidents de cybersécurité. Cas pratiques africains.',
      'bloc': 'E',
      'type': 'edefence',
      'niveau': 'avance',
      'duree_heures': 60,
      'prix': 140000,
      'partenaire': 'E-DEFENCE Academy',
      'partenaire_code': 'EDEFENCE',
      'nombre_labs': 12,
      'paiement_echelonne': true,
    },
    {
      'code': 'E02-CHFI',
      'titre': 'CHFI — Computer Hacking Forensic Investigator',
      'description': 'Certification EC-Council pour investigators numériques. Collecte preuves, analyse disques, mobile forensics.',
      'bloc': 'E',
      'type': 'international',
      'niveau': 'avance',
      'duree_heures': 85,
      'prix': 480000,
      'partenaire': 'EC-Council',
      'partenaire_code': 'ECCOUNCIL',
      'nombre_labs': 18,
      'paiement_echelonne': true,
    },
  ];
}
