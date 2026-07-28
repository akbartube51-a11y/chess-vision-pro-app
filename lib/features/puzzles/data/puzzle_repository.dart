import '../../../core/services/database_service.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_progress.dart';
import 'sample_puzzles.dart';

class PuzzleRepository {
  PuzzleRepository(this._db);

  final DatabaseService _db;

  Future<void> seedSamplePuzzles() async {
    final count = await _db.db.rawQuery('SELECT COUNT(*) as c FROM puzzles');
    if ((count.first['c'] as int) > 0) return;

    final batch = _db.db.batch();
    for (final p in kSamplePuzzles) {
      batch.insert('puzzles', p);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Puzzle>> fetchPuzzles({int limit = 50, int offset = 0}) async {
    final rows = await _db.db.query(
      'puzzles',
      limit: limit,
      offset: offset,
      orderBy: 'rating ASC',
    );
    return rows.map(Puzzle.fromMap).toList();
  }

  Future<Puzzle?> fetchPuzzleById(int id) async {
    final rows =
        await _db.db.query('puzzles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Puzzle.fromMap(rows.first);
  }

  Future<List<Puzzle>> fetchPuzzlesByTheme(String theme,
      {int limit = 20}) async {
    final rows = await _db.db.rawQuery(
      "SELECT * FROM puzzles WHERE themes LIKE ? ORDER BY rating ASC LIMIT ?",
      ['%$theme%', limit],
    );
    return rows.map(Puzzle.fromMap).toList();
  }

  Future<int> insertPuzzle(Puzzle puzzle) async {
    return _db.db.insert('puzzles', puzzle.toMap());
  }

  // -- Progress --

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
