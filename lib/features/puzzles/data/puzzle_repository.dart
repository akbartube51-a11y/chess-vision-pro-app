import 'package:sqflite/sqflite.dart';

import '../../../core/services/database_service.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_progress.dart';
import 'puzzle_sync_models.dart';
import 'sample_puzzles.dart';

class PuzzleRepository {
  PuzzleRepository(this._db);

  final DatabaseService _db;

  Future<void> seedSamplePuzzles() async {
    final count = await _db.db.rawQuery('SELECT COUNT(*) as c FROM puzzles');
    if ((count.first['c'] as int) > 0) return;

    final batch = _db.db.batch();
    for (final puzzle in kSamplePuzzles) {
      batch.insert('puzzles', puzzle);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Puzzle>> fetchPuzzles({
    int limit = 50,
    int offset = 0,
    String? themeFilter,
  }) async {
    if (themeFilter != null && themeFilter.isNotEmpty) {
      return fetchPuzzlesByTheme(themeFilter, limit: limit, offset: offset);
    }
    final rows = await _db.db.query(
      'puzzles',
      limit: limit,
      offset: offset,
      orderBy: 'rating ASC, id ASC',
    );
    return rows.map(Puzzle.fromMap).toList();
  }

  Future<Puzzle?> fetchPuzzleById(int id) async {
    final rows = await _db.db.query('puzzles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Puzzle.fromMap(rows.first);
  }

  Future<List<Puzzle>> fetchPuzzlesByTheme(
    String theme, {
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _db.db.rawQuery(
      'SELECT * FROM puzzles WHERE themes LIKE ? ORDER BY rating ASC, id ASC LIMIT ? OFFSET ?',
      ['%$theme%', limit, offset],
    );
    return rows.map(Puzzle.fromMap).toList();
  }

  Future<List<Puzzle>> fetchReviewQueue({
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _db.db.rawQuery(
      '''
      SELECT puzzles.*
      FROM puzzles
      JOIN puzzle_progress ON puzzle_progress.puzzle_id = puzzles.id
      WHERE puzzle_progress.solved = 0 OR puzzle_progress.attempts > 0
      ORDER BY puzzle_progress.attempts DESC, puzzle_progress.last_attempted ASC, puzzles.rating ASC
      LIMIT ? OFFSET ?
      ''',
      [limit, offset],
    );
    return rows.map(Puzzle.fromMap).toList();
  }

  Future<List<String>> fetchAvailableThemes({int limit = 24}) async {
    final rows = await _db.db.query('puzzles', columns: ['themes']);
    final values = <String>{};
    for (final row in rows) {
      final raw = row['themes'] as String? ?? '';
      for (final theme in raw.split(' ')) {
        if (theme.trim().isNotEmpty) {
          values.add(theme.trim());
        }
      }
    }
    final sorted = values.toList()..sort();
    return sorted.take(limit).toList(growable: false);
  }

  Future<int> insertPuzzle(Puzzle puzzle) {
    return _db.db.insert('puzzles', puzzle.toMap());
  }

  Future<void> upsertImportedPuzzles(List<ImportedPuzzle> puzzles) async {
    if (puzzles.isEmpty) return;
    final existingIds = await _loadExistingIdsByExternalId(
      puzzles.first.source,
      puzzles.map((item) => item.externalId).toList(growable: false),
    );
    final batch = _db.db.batch();
    for (final puzzle in puzzles) {
      final existingId = existingIds[puzzle.externalId];
      final data = puzzle.toDatabaseMap();
      if (existingId != null) {
        batch.update('puzzles', data, where: 'id = ?', whereArgs: [existingId]);
      } else {
        batch.insert(
          'puzzles',
          data,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, int>> _loadExistingIdsByExternalId(
    String source,
    List<String> externalIds,
  ) async {
    if (externalIds.isEmpty) return const <String, int>{};
    final placeholders = List.filled(externalIds.length, '?').join(',');
    final rows = await _db.db.rawQuery(
      'SELECT id, external_id FROM puzzles WHERE source = ? AND external_id IN ($placeholders)',
      [source, ...externalIds],
    );
    return {
      for (final row in rows)
        row['external_id'] as String: row['id'] as int,
    };
  }

  Future<PuzzleSyncState?> fetchSyncState(String sourceId) async {
    final rows = await _db.db.query(
      'puzzle_sync_state',
      where: 'source_id = ?',
      whereArgs: [sourceId],
    );
    if (rows.isEmpty) return null;
    return PuzzleSyncState.fromMap(rows.first);
  }

  Future<void> saveSyncState(PuzzleSyncState state) async {
    await _db.db.insert(
      'puzzle_sync_state',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PuzzleProgress?> fetchProgress(int puzzleId) async {
    final rows = await _db.db.query(
      'puzzle_progress',
      where: 'puzzle_id = ?',
      whereArgs: [puzzleId],
    );
    if (rows.isEmpty) return null;
    return PuzzleProgress.fromMap(rows.first);
  }

  Future<void> saveProgress(PuzzleProgress progress) async {
    final existing = await fetchProgress(progress.puzzleId);
    if (existing == null) {
      await _db.db.insert('puzzle_progress', progress.toMap());
    } else {
      await _db.db.update(
        'puzzle_progress',
        progress.toMap(),
        where: 'puzzle_id = ?',
        whereArgs: [progress.puzzleId],
      );
    }
  }

  Future<int> countSolved() async {
    final rows = await _db.db.rawQuery(
      'SELECT COUNT(*) as c FROM puzzle_progress WHERE solved = 1',
    );
    return rows.first['c'] as int;
  }

  Future<int> countTotal() async {
    final rows = await _db.db.rawQuery('SELECT COUNT(*) as c FROM puzzles');
    return rows.first['c'] as int;
  }
}
