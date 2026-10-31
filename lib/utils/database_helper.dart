import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/study_session.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Future<Database>? _database;

  Future<Database> initDB() {
    return _database ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final fullPath = path.join(databasePath, 'study_tracker.db');

    return openDatabase(
      fullPath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE study_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            subject TEXT NOT NULL,
            duration INTEGER NOT NULL,
            notes TEXT,
            isFavorite INTEGER NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertSession(StudySession session) async {
    final values = session.toMap()..remove('id');
    return (await initDB()).insert('study_sessions', values);
  }

  Future<int> updateSession(StudySession session) async {
    final id = session.id;
    if (id == null) {
      throw ArgumentError('Cannot update a study session without an id.');
    }

    return (await initDB()).update(
      'study_sessions',
      session.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSession(int id) async {
    return (await initDB()).delete(
      'study_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getSessionsCount() async {
    final result = await (await initDB()).rawQuery(
      'SELECT COUNT(*) AS count FROM study_sessions',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getNonFavoriteSessionsCount() async {
    final result = await (await initDB()).rawQuery(
      'SELECT COUNT(*) AS count FROM study_sessions WHERE isFavorite = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteNonFavoriteSessions() async {
    return (await initDB()).delete(
      'study_sessions',
      where: 'isFavorite = 0',
    );
  }

  Future<int> getTotalDuration() async {
    final result = await (await initDB()).rawQuery(
      'SELECT COALESCE(SUM(duration), 0) AS total FROM study_sessions',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<StudySession>> getPaginatedSessions({
    required int page,
    int limit = 10,
  }) async {
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'Must be 1 or greater.');
    }
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be 1 or greater.');
    }

    final rows = await (await initDB()).query(
      'study_sessions',
      orderBy: 'createdAt DESC, id DESC',
      limit: limit,
      offset: (page - 1) * limit,
    );
    return rows.map(StudySession.fromMap).toList();
  }
}
