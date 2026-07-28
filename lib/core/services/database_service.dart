import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'chess_vision_pro.db'),
      version: 1,
      onCreate: _onCreate,
    );
  }

  Database get db {
    assert(_db != null, 'DatabaseService not initialized. Call init() first.');
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE puzzles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        external_id TEXT,
        fen TEXT NOT NULL,
        moves TEXT NOT NULL,
        rating INTEGER NOT NULL DEFAULT 1500,
        themes TEXT NOT NULL DEFAULT '',
        opening_tags TEXT NOT NULL DEFAULT '',
        source TEXT NOT NULL DEFAULT 'local'
      )
    ''');

    await db.execute('''
      CREATE TABLE puzzle_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        puzzle_id INTEGER NOT NULL,
        solved INTEGER NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_attempted TEXT,
        FOREIGN KEY (puzzle_id) REFERENCES puzzles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
