class StudySession {
  StudySession({
    this.id,
    required this.title,
    required this.subject,
    required this.duration,
    this.notes,
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String title;
  final String subject;
  final int duration;
  final String? notes;
  final bool isFavorite;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subject': subject,
        'duration': duration,
        'notes': notes,
        'isFavorite': isFavorite ? 1 : 0,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory StudySession.fromMap(Map<String, dynamic> map) => StudySession(
        id: map['id'] as int?,
        title: map['title'] as String,
        subject: map['subject'] as String,
        duration: map['duration'] as int,
        notes: map['notes'] as String?,
        isFavorite: (map['isFavorite'] as num) != 0,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  StudySession copyWith({
    int? id,
    String? title,
    String? subject,
    int? duration,
    String? notes,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
