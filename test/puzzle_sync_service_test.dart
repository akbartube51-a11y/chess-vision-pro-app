import 'package:chess_vision_pro/core/services/database_service.dart';
import 'package:chess_vision_pro/features/puzzles/data/puzzle_repository.dart';
import 'package:chess_vision_pro/features/puzzles/data/puzzle_source.dart';
import 'package:chess_vision_pro/features/puzzles/data/puzzle_sync_models.dart';
import 'package:chess_vision_pro/features/puzzles/data/puzzle_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retries failed sync and persists state', () async {
    final repository = _FakePuzzleRepository();
    final service = PuzzleSyncService(repository);
    final source = _RetryingSource();

    final report = await service.syncSource(
      source,
      uri: Uri.parse('https://example.com/puzzles.csv'),
      batchSize: 1,
      maxRetries: 2,
    );

    expect(report.importedCount, equals(1));
    expect(repository.savedPuzzles.single.externalId, equals('sync-1'));
    expect(repository.savedState?.cursor, equals('1'));
    expect(repository.savedState?.lastError, isNull);
  });
}

class _RetryingSource extends PuzzleSource {
  int attempts = 0;

  @override
  String get attribution => 'Test data';

  @override
  Uri? get defaultUri => Uri.parse('https://example.com/puzzles.csv');

  @override
  String get displayName => 'Retry source';

  @override
  String get licenseId => 'CC0-1.0';

  @override
  String get sourceId => 'retry';

  @override
  Stream<PuzzleSourceChunk> streamPuzzles({
    required Uri uri,
    String? cursor,
    int batchSize = 250,
  }) async* {
    attempts++;
    if (attempts == 1) {
      throw const PuzzleSourceException('temporary failure');
    }
    yield const PuzzleSourceChunk(
      puzzles: [
        ImportedPuzzle(
          externalId: 'sync-1',
          fen: '8/8/8/8/8/8/8/K6k w - - 0 1',
          moves: ['a1a2', 'h1h2'],
          rating: 1000,
          themes: ['mateIn1'],
          openingTags: [],
          source: 'retry',
        ),
      ],
      nextCursor: '1',
      isLastChunk: true,
    );
  }
}

class _FakePuzzleRepository extends PuzzleRepository {
  _FakePuzzleRepository() : super(DatabaseService());

  final List<ImportedPuzzle> savedPuzzles = [];
  PuzzleSyncState? savedState;

  @override
  Future<void> upsertImportedPuzzles(List<ImportedPuzzle> puzzles) async {
    savedPuzzles.addAll(puzzles);
  }

  @override
  Future<PuzzleSyncState?> fetchSyncState(String sourceId) async => savedState;

  @override
  Future<void> saveSyncState(PuzzleSyncState state) async {
    savedState = state;
  }
}
