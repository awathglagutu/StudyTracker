import 'dart:math';
import '../models/study_session.dart';

List<StudySession> generateDummySessions(int count) {
  final random = Random();
  final subjects = [
    'Mathematics',
    'Science',
    'English',
    'History',
    'Computer Science',
    'Other',
  ];
  final titlePrefixes = [
    'Chapter Revision',
    'Practice Problems',
    'Lecture Notes Review',
    'Exam Preparation',
    'Assignment Work',
    'Lab Exercises',
  ];
  final sampleNotes = [
    'Reviewed core concepts and completed exercises.',
    'Focused on weak areas and practice questions.',
    'Prepared outline for upcoming test.',
    null,
  ];

  return List.generate(count, (index) {
    final subject = subjects[random.nextInt(subjects.length)];
    final title =
        '${titlePrefixes[random.nextInt(titlePrefixes.length)]} #${index + 1}';
    final duration = (random.nextInt(8) + 1) * 15; // 15, 30, 45... mins
    final note = sampleNotes[random.nextInt(sampleNotes.length)];
    return StudySession(
      title: title,
      subject: subject,
      duration: duration,
      notes: note,
      isFavorite: false,
    );
  });
}
