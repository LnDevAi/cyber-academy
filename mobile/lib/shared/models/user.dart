class User {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final int xpPoints;
  final int level;
  final int streakDays;
  final int coursesCompleted;
  final int labsCompleted;
  final int certificationsEarned;
  final String role;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.xpPoints = 0,
    this.level = 1,
    this.streakDays = 0,
    this.coursesCompleted = 0,
    this.labsCompleted = 0,
    this.certificationsEarned = 0,
    this.role = 'apprenant',
  });

  String get displayName =>
      (firstName != null && lastName != null)
          ? '$firstName $lastName'
          : username;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['prenom'],
      lastName: json['last_name'] ?? json['nom'],
      avatar: json['avatar'] ?? json['photo'],
      xpPoints: json['xp_points'] ?? json['xp'] ?? 0,
      level: json['level'] ?? json['niveau'] ?? 1,
      streakDays: json['streak_days'] ?? json['streak'] ?? 0,
      coursesCompleted: json['courses_completed'] ?? 0,
      labsCompleted: json['labs_completed'] ?? 0,
      certificationsEarned: json['certifications_earned'] ?? 0,
      role: json['role'] ?? 'apprenant',
    );
  }
}

class Course {
  final String id;
  final String title;
  final String description;
  final String level;
  final String category;
  final int duration;
  final String? thumbnail;
  final int lessonsCount;
  final double? progressPercent;
  final bool isEnrolled;
  final double rating;
  final int enrolledCount;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.category,
    required this.duration,
    this.thumbnail,
    this.lessonsCount = 0,
    this.progressPercent,
    this.isEnrolled = false,
    this.rating = 0,
    this.enrolledCount = 0,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['titre'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] ?? json['niveau'] ?? 'Débutant',
      category: json['category'] ?? json['categorie'] ?? '',
      duration: json['duration'] ?? json['duree'] ?? 0,
      thumbnail: json['thumbnail'] ?? json['image'],
      lessonsCount: json['lessons_count'] ?? json['nb_lecons'] ?? 0,
      progressPercent: (json['progress_percent'] ?? json['progression'] ?? 0).toDouble(),
      isEnrolled: json['is_enrolled'] ?? json['inscrit'] ?? false,
      rating: (json['rating'] ?? json['note'] ?? 0).toDouble(),
      enrolledCount: json['enrolled_count'] ?? json['nb_apprenants'] ?? 0,
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String content;
  final int order;
  final int duration;
  final bool isCompleted;
  final String type;

  const Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    required this.duration,
    this.isCompleted = false,
    this.type = 'text',
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['titre'] ?? '',
      content: json['content'] ?? json['contenu'] ?? '',
      order: json['order'] ?? json['ordre'] ?? 0,
      duration: json['duration'] ?? json['duree'] ?? 0,
      isCompleted: json['is_completed'] ?? json['complete'] ?? false,
      type: json['type'] ?? 'text',
    );
  }
}

class Lab {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String technology;
  final int duration;
  final String? thumbnail;
  final bool isCompleted;
  final String? sessionStatus;
  final List<String> objectives;

  const Lab({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.technology,
    required this.duration,
    this.thumbnail,
    this.isCompleted = false,
    this.sessionStatus,
    this.objectives = const [],
  });

  factory Lab.fromJson(Map<String, dynamic> json) {
    return Lab(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['titre'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? json['difficulte'] ?? 'Débutant',
      technology: json['technology'] ?? json['technologie'] ?? '',
      duration: json['duration'] ?? json['duree'] ?? 0,
      thumbnail: json['thumbnail'] ?? json['image'],
      isCompleted: json['is_completed'] ?? false,
      sessionStatus: json['session_status'],
      objectives: List<String>.from(json['objectives'] ?? json['objectifs'] ?? []),
    );
  }
}

class Certification {
  final String id;
  final String title;
  final String description;
  final String status;
  final double? score;
  final DateTime? obtainedAt;
  final DateTime? expiresAt;
  final String? badgeUrl;
  final String? certificateUrl;

  const Certification({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.score,
    this.obtainedAt,
    this.expiresAt,
    this.badgeUrl,
    this.certificateUrl,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['titre'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? json['statut'] ?? 'en_cours',
      score: json['score'] != null ? (json['score']).toDouble() : null,
      obtainedAt: json['obtained_at'] != null
          ? DateTime.tryParse(json['obtained_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      badgeUrl: json['badge_url'] ?? json['badge'],
      certificateUrl: json['certificate_url'] ?? json['certificat'],
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatar;
  final int xpPoints;
  final int coursesCompleted;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatar,
    required this.xpPoints,
    this.coursesCompleted = 0,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {bool isCurrentUser = false}) {
    return LeaderboardEntry(
      rank: json['rank'] ?? json['rang'] ?? 0,
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'],
      xpPoints: json['xp_points'] ?? json['xp'] ?? 0,
      coursesCompleted: json['courses_completed'] ?? 0,
      isCurrentUser: isCurrentUser,
    );
  }
}
