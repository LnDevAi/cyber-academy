import 'course.dart';

class Enrollment {
  final String id;
  final String userId;
  final String courseCode;
  final String? courseTitre;
  final String statut; // 'actif' | 'en_pause' | 'termine' | 'expire'
  final double progression; // 0-100
  final DateTime dateDebut;
  final DateTime? dateFin;
  final List<ModuleProgress> moduleProgresses;
  final int labsCompletes;
  final int labsTotal;
  final String? mentorId;
  final Course? course;

  const Enrollment({
    required this.id,
    required this.userId,
    required this.courseCode,
    this.courseTitre,
    required this.statut,
    required this.progression,
    required this.dateDebut,
    this.dateFin,
    this.moduleProgresses = const [],
    this.labsCompletes = 0,
    this.labsTotal = 0,
    this.mentorId,
    this.course,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      courseCode: json['course_code'] ?? '',
      courseTitre: json['course_titre'],
      statut: json['statut'] ?? 'actif',
      progression: (json['progression'] ?? 0).toDouble(),
      dateDebut: json['date_debut'] != null
          ? DateTime.parse(json['date_debut'])
          : DateTime.now(),
      dateFin: json['date_fin'] != null ? DateTime.parse(json['date_fin']) : null,
      moduleProgresses: json['module_progresses'] != null
          ? (json['module_progresses'] as List)
              .map((m) => ModuleProgress.fromJson(m))
              .toList()
          : [],
      labsCompletes: json['labs_completes'] ?? 0,
      labsTotal: json['labs_total'] ?? 0,
      mentorId: json['mentor_id']?.toString(),
      course: json['course'] != null ? Course.fromJson(json['course']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'course_code': courseCode,
    'course_titre': courseTitre,
    'statut': statut,
    'progression': progression,
    'date_debut': dateDebut.toIso8601String(),
    'date_fin': dateFin?.toIso8601String(),
    'labs_completes': labsCompletes,
    'labs_total': labsTotal,
  };

  bool get isTermine => statut == 'termine';
  bool get isActif => statut == 'actif';
}

class ModuleProgress {
  final String moduleId;
  final String moduleTitre;
  final bool complete;
  final double progression;

  const ModuleProgress({
    required this.moduleId,
    required this.moduleTitre,
    required this.complete,
    required this.progression,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['module_id']?.toString() ?? '',
      moduleTitre: json['module_titre'] ?? '',
      complete: json['complete'] ?? false,
      progression: (json['progression'] ?? 0).toDouble(),
    );
  }
}
