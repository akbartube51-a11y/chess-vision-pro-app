import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'chess_vision_pro.db'),
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
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

    await _createIndexes(db);
    await _createSyncStateTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createIndexes(db);
      await _createSyncStateTable(db);
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_puzzles_rating ON puzzles (rating)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_puzzles_source ON puzzles (source)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_puzzles_source_external ON puzzles (source, external_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_puzzle_progress_lookup ON puzzle_progress (puzzle_id, solved, attempts)',
    );
  }

  Future<void> _createSyncStateTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS puzzle_sync_state (
        source_id TEXT PRIMARY KEY,
        last_synced_at TEXT,
        cursor TEXT,
        dataset_version TEXT,
        content_hash TEXT,
        imported_count INTEGER NOT NULL DEFAULT 0,
        attribution TEXT NOT NULL DEFAULT '',
        last_error TEXT
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
